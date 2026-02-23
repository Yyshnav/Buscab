import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/utils/map_utils.dart';

class TrackCabPage extends StatefulWidget {
  final int vehicleId;
  final String vehicleNo;

  const TrackCabPage({
    super.key,
    required this.vehicleId,
    required this.vehicleNo,
  });

  @override
  State<TrackCabPage> createState() => _TrackCabPageState();
}

class _TrackCabPageState extends State<TrackCabPage> {
  LatLng? _cabLocation;
  GoogleMapController? _mapController;
  Timer? _timer;
  bool _isLoading = true;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _enableHybridComposition();
    _loadCustomMarker();
    _fetchLocation();
    // Update location every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLocation();
    });
  }

  void _enableHybridComposition() {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  Future<void> _loadCustomMarker() async {
    _carIcon = await MapUtils.getVehicleMarker();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final response = await ApiService.getVehicleLocation(widget.vehicleId);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['latitude'] != null && data['longitude'] != null) {
          final newLocation = LatLng(
            double.parse(data['latitude'].toString()),
            double.parse(data['longitude'].toString()),
          );

          if (mounted) {
            setState(() {
              _cabLocation = newLocation;
              _isLoading = false;
            });

            // Move camera to cab location
            _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "TRACKING CAB: ${widget.vehicleNo}",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cabLocation ?? const LatLng(0, 0),
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Apply dark theme style to map if possible,
              // or just keep default for now as premium look depends on it.
            },
            markers: _cabLocation != null
                ? {
                    Marker(
                      markerId: MarkerId(widget.vehicleId.toString()),
                      position: _cabLocation!,
                      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
                      anchor: const Offset(0.5, 0.5),
                      infoWindow: InfoWindow(title: widget.vehicleNo),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          if (_isLoading)
            Container(
              color: AppTheme.background.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LIVE STATUS",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _cabLocation != null
                                  ? "Tracking ${widget.vehicleNo}..."
                                  : "Waiting for signal...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
