import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

enum AppLocationState {
  idle,
  checking,
  ready,
  serviceDisabled,
  denied,
  permanentlyDenied,
  failed,
}

class EventLocation {
  const EventLocation({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });

  final double lat;
  final double lng;
  final double accuracy;

  Map<String, dynamic> toRawPayload() => <String, dynamic>{
    'lat': lat,
    'lng': lng,
    'accuracy': accuracy,
  };
}

class LocationProvider extends ChangeNotifier {
  AppLocationState state = AppLocationState.idle;
  EventLocation? location;
  Object? error;

  bool get loading => state == AppLocationState.checking;
  bool get needsLocationSettings => state == AppLocationState.serviceDisabled;
  bool get needsAppSettings => state == AppLocationState.permanentlyDenied;

  Future<EventLocation?> getEventLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (loading) return location;
    _update(AppLocationState.checking);
    error = null;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _update(AppLocationState.serviceDisabled);
        return null;
      }

      var permission = await permissions.Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        permission = await permissions.Permission.locationWhenInUse.request();
      }
      if (permission.isPermanentlyDenied || permission.isRestricted) {
        _update(AppLocationState.permanentlyDenied);
        return null;
      }
      if (!permission.isGranted && !permission.isLimited) {
        _update(AppLocationState.denied);
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      location = EventLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );
      _update(AppLocationState.ready);
      return location;
    } catch (exception) {
      error = exception;
      _update(AppLocationState.failed);
      return null;
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => permissions.openAppSettings();

  void _update(AppLocationState next) {
    state = next;
    notifyListeners();
  }
}
