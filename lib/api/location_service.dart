import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;
  bool _isTracking = false;
  int? _vehicleId;

  bool get isTracking => _isTracking;

  Future<void> startTracking(int vehicleId) async {
    if (_isTracking) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    _vehicleId = vehicleId;
    _isTracking = true;
    _updateLocation();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateLocation();
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _isTracking = false;
    _vehicleId = null;
  }

  Future<void> _updateLocation() async {
    if (_vehicleId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await ApiService.updateLocation({
        'vehicle_id': _vehicleId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      debugPrint(
        "Location updated: ${position.latitude}, ${position.longitude}",
      );
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }
}
