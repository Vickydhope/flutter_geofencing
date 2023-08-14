import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofencing/gefence_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Set<Circle>? circles;

  LatLng _createCenter() {
    return _createLatLng(37.3304198, -122.03014382);
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }

  final geofencingService = GeofenceService();

  StreamSubscription? _subscription;

  static const LatLng _kMapCenter = LatLng(37.3304198, -122.03014382);

  static const CameraPosition _kInitialPosition =
  CameraPosition(target: _kMapCenter, zoom: 13.0, tilt: 0, bearing: 0);

  @override
  void initState() {
    initGeofencingServices();

    circles = {
      Circle(
          circleId: const CircleId("myCircle"),
          radius: 1000,
          center: _createLatLng(37.3304198, -122.03014382),
          fillColor: Colors.green.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
          onTap: () {
            if (kDebugMode) {
              print('circle pressed');
            }
          })
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var distance = geofencingService.getDistance(
              37.3304198,
              -122.03014382,
              geofencingService.currentLocation?.latitude ?? 0,
              geofencingService.currentLocation?.longitude ?? 0);
        },
        child: const Icon(Icons.location_on),
      ),
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
          child: GoogleMap(
            onLongPress: (argument) {
              setState(() {
                circles?.add(_createCircle(argument));
              });
            },
            myLocationEnabled: true,
            initialCameraPosition: _kInitialPosition,
            circles: circles ?? {},
          )),
    );
  }

  void initGeofencingServices() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.denied) {
        startService();
      } else {
        if (kDebugMode) {
          print("Location Permission should be granted to use GeoFenceService");
        }
      }
    } else {
      startService();
    }
  }

  void startService() {
    geofencingService.startService(
      fenceCenterLatitude: 37.33067599,
      fenceCenterLongitude: -122.03014382,
      radius: 1000,
    );

    _subscription = geofencingService.getFenceStatusListener.listen((event) {
      if (kDebugMode) {
        print(
          "You have : ${event.status} "
              "and distance: ${event.distance}",
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Circle _createCircle(LatLng location) {
    return Circle(
        circleId:  CircleId("myCircle${location.latitude}"),
        radius: 1000,
        center: _createLatLng(location.latitude, location.longitude),
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 1,
        onTap: () {
          if (kDebugMode) {
            print('circle pressed');
          }
        });
  }
}
