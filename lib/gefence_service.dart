import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import 'geofence_status.dart';

class GeofenceService {
  final StreamController<GeofenceStatus> _geofenceController =
      StreamController();

  Stream<GeofenceStatus> get getFenceStatusListener =>
      _geofenceController.stream;

  StreamSubscription<Position>? _positionStream;

  var _status = Status.INITIALIZE;

  late double _fenceLatitude;
  late double _fenceLongitude;
  late double _radius;
  Position? currentLocation;

  static const MethodChannel _channel = MethodChannel("flutter_geofence");

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod("getPlatformVersion");
    return version;
  }

  Status getStatus() {
    return _status;
  }

  Position? getCurrentLocation() {
    return currentLocation;
  }

  void stopService() {
    try {
      _positionStream?.cancel();
    } catch (error) {
      if (kDebugMode) {
        print("Error while stopping the FenceService : ${error.toString()}");
      }
    }
  }

  Future<void> startService({
    required double fenceCenterLatitude,
    required double fenceCenterLongitude,
    required double radius,
  }) async {
    _geofenceController.add(GeofenceStatus(status: Status.INITIALIZE));
    _fenceLatitude = fenceCenterLatitude;
    _fenceLongitude = fenceCenterLongitude;
    _radius = radius;

    //check for location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        print("Exception Occurred : Location Service is not enabled");
      }
      _geofenceController.add(GeofenceStatus(status: Status.ERROR));
      return;
    }

    // check location permissions
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (kDebugMode) {
        print("Exception Occurred : Location Permission is Required");
      }
      _geofenceController.add(GeofenceStatus(status: Status.ERROR));
      return;
    }

    LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 2),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );
    }

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        currentLocation = position;
        final distance = getDistance(
          position.latitude,
          position.longitude,
          _fenceLatitude,
          _fenceLongitude,
        );

        Status status = distance <= _radius ? Status.ENTER : Status.EXIT;

        if (_status != status) {
          _status = status;

          final geofenceStatus = GeofenceStatus(status: _status);

          geofenceStatus.latitude = position.latitude;
          geofenceStatus.longitude = position.longitude;
          geofenceStatus.distance = distance;

          _geofenceController.add(geofenceStatus);
        }
      }
    });
  }

  ///Calculate distance between two latitudes and longitudes
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    double theta = lon1 - lon2;
    double dist = sin(toRadians(lat1)) * sin(toRadians(lat2)) +
        cos(toRadians(lat1)) * cos(toRadians(lat2)) * cos(toRadians(theta));

    dist = acos(dist);

    dist = toDegrees(dist);
    dist = dist * 60 * 1.1515;
    dist = dist * 1000 * 1.609344;

    ///dist in meter
    return dist;
  }

  double toRadians(double degree) {
    return degree * pi / 180;
  }

  double toDegrees(double radian) {
    return radian * 180 / pi;
  }
}
