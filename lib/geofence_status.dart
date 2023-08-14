// ignore_for_file: constant_identifier_names

class GeofenceStatus {
  final Status status;

  double latitude = 0;
  double longitude = 0;
  double distance = 0;

  GeofenceStatus({required this.status});
}

enum Status { INITIALIZE, ENTER, EXIT, STOP, ERROR }
