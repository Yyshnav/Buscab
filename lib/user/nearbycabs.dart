import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/utils/map_utils.dart';
import 'bookinghistory.dart';

class NearbyCabsUI extends StatefulWidget {
  const NearbyCabsUI({super.key});

  @override
  State<NearbyCabsUI> createState() => _NearbyCabsUIState();
}

class _NearbyCabsUIState extends State<NearbyCabsUI> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();

  List<dynamic> cabs = [];
  bool isLoading = true;
  bool viewMap = false;
  String selectedType = "All";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  BitmapDescriptor? _carIcon;
  GoogleMapController? _mapController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMarker();
    _fetchCabs();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _fetchCabs(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMarker() async {
    _carIcon = await MapUtils.getVehicleMarker();
    if (mounted) setState(() {});
  }

  void _fetchCabs({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    try {
      final response = await ApiService.getVehicles(
        pickup: pickup.text.trim().isEmpty ? null : pickup.text.trim(),
        drop: drop.text.trim().isEmpty ? null : drop.text.trim(),
        cabType: selectedType == "All" ? null : selectedType,
      );
      if (response.statusCode == 200) {
        setState(() {
          cabs = response.data;
          isLoading = false;
        });
        if (viewMap && cabs.isNotEmpty && _mapController != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(
                double.parse(cabs.first['latitude'].toString()),
                double.parse(cabs.first['longitude'].toString()),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load cabs: $e")));
      }
    }
  }

  String calculateETA(String? distance) {
    if (distance == null) return "N/A";
    final double dist =
        double.tryParse(distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (dist == 0.0) return "N/A";
    final int minutes = (dist / 0.5).round();
    return "$minutes mins";
  }

  double calculateFare(Map<String, dynamic> cab) {
    final double rate =
        double.tryParse(cab["per_km_rate"]?.toString() ?? "0") ?? 0.0;
    final double dist =
        double.tryParse(cab["distance_km"]?.toString() ?? "0") ?? 0.0;
    if (rate > 0 && dist > 0) return rate * dist;
    final String? distanceStr = cab["distance"];
    if (distanceStr == null) return 50.0;
    final km =
        double.tryParse(distanceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
    return km * (rate > 0 ? rate : 25);
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void showBookingSheet(Map<String, dynamic> cab) {
    final double fare = calculateFare(cab);
    final String eta = calculateETA(cab["distance"]);
    int requestedSeats = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (cab["vehicle_image"] != null) ...[
                    Hero(
                      tag: "vehicle_${cab['id']}",
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: NetworkImage(
                              "${ApiService.baseUrl}${cab["vehicle_image"]}",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cab["owner_name"] ?? "Taxi Service",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${cab["vehicle_class"]} • ${cab["vehicle_model"]}",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cab["mobile_number"] != null)
                        _buildCircleButton(
                          Icons.call_rounded,
                          () => _makeCall(cab["mobile_number"].toString()),
                          Colors.greenAccent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildDetailChip(
                        Icons.local_gas_station_rounded,
                        "Fuel",
                        cab["fuel_type"] ?? "N/A",
                      ),
                      _buildDetailChip(
                        Icons.airline_seat_recline_normal_rounded,
                        "Seats",
                        "${cab["seating_capacity"] ?? 4}",
                      ),
                      _buildDetailChip(
                        Icons.category_rounded,
                        "Type",
                        cab["cab_type"] ?? "N/A",
                      ),
                      _buildDetailChip(
                        Icons.numbers_rounded,
                        "Plate",
                        cab["vehicle_no"] ?? "N/A",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Container(
                  //   padding: const EdgeInsets.all(20),
                  //   decoration: BoxDecoration(
                  //     color: AppTheme.surface,
                  //     borderRadius: BorderRadius.circular(24),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.timer_outlined, color: AppTheme.primary),
                  //       const SizedBox(width: 16),
                  //       Expanded(
                  //         child: Text(
                  //           "ETA",
                  //           style: TextStyle(
                  //             color: AppTheme.textDim,
                  //             fontSize: 10,
                  //             fontWeight: FontWeight.w900,
                  //             letterSpacing: 1,
                  //           ),
                  //         ),
                  //       ),
                  //       Text(
                  //         eta,
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 32),
                  _buildPickerButton(
                    icon: Icons.calendar_month_rounded,
                    label: selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null)
                        setModalState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPickerButton(
                    icon: Icons.access_time_rounded,
                    label: selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null)
                        setModalState(() => selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 32),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text(
                  //       "TOTAL",
                  //       style: TextStyle(
                  //         color: Colors.white54,
                  //         fontWeight: FontWeight.w900,
                  //         fontSize: 10,
                  //         letterSpacing: 1,
                  //       ),
                  //     ),
                  //     Text(
                  //       "₹${(fare * requestedSeats).toStringAsFixed(2)}",
                  //       style: const TextStyle(
                  //         color: Colors.greenAccent,
                  //         fontSize: 28,
                  //         fontWeight: FontWeight.w900,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleBooking(cab, fare, requestedSeats),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "BOOK NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleBooking(
    Map<String, dynamic> cab,
    double fare,
    int requestedSeats,
  ) async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date and time")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final data = {
        'login_id': userId,
        'status': 'Pending',
        'vehicle_no': int.parse(cab["id"].toString()),
        'date':
            "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
        'time':
            "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
        'total_amount': fare * requestedSeats,
        'requested_seats': requestedSeats,
      };

      final response = await ApiService.bookVehicle(data);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking request sent!"),
            backgroundColor: Colors.greenAccent,
          ),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Booking failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "CABS",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => viewMap = !viewMap),
            icon: Icon(
              viewMap ? Icons.list_rounded : Icons.map_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!viewMap)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          pickup,
                          "Pickup",
                          Icons.my_location_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          drop,
                          "Drop",
                          Icons.location_on_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fetchCabs,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text(
                        "SEARCH",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          if (!viewMap) _buildFilterBar(),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : viewMap
                ? _buildMapView()
                : cabs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: cabs.length,
                    itemBuilder: (context, index) =>
                        _buildCabCard(cabs[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24, bottom: 24),
      child: Row(
        children: ["All", "SUV", "Hatchback", "Sedan", "MUV/MPV"].map((type) {
          final isSelected = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedType = type);
                _fetchCabs();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white10,
                  ),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDim,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCabCard(Map<String, dynamic> cab, int index) {
    final hasRoute =
        (cab['pickup_location'] != null &&
            cab['pickup_location'].toString().isNotEmpty) ||
        (cab['drop_location'] != null &&
            cab['drop_location'].toString().isNotEmpty);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => showBookingSheet(cab),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            if (cab["vehicle_image"] != null)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      "${ApiService.baseUrl}${cab["vehicle_image"]}",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cab["owner_name"] ?? "Taxi",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Text(
                      //   "₹${calculateFare(cab).toInt()}",
                      //   style: const TextStyle(
                      //     color: Colors.greenAccent,
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.w900,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${cab["vehicle_model"]}",
                    style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                  ),
                  if (hasRoute) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${cab['pickup_location'] ?? '?'}  →  ${cab['drop_location'] ?? '?'}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppTheme.textDim,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        calculateETA(cab["distance"]),
                        style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.airline_seat_recline_normal_rounded,
                        size: 14,
                        color: AppTheme.textDim,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${cab["seating_capacity"] ?? 4}",
                        style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("No cabs found", style: TextStyle(color: AppTheme.textDim)),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    Set<Marker> markers = cabs
        .where((cab) => cab['latitude'] != null && cab['longitude'] != null)
        .map((cab) {
          return Marker(
            markerId: MarkerId(cab['id'].toString()),
            position: LatLng(
              double.parse(cab['latitude'].toString()),
              double.parse(cab['longitude'].toString()),
            ),
            icon: _carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: cab['owner_name'],
              snippet:
                  "${cab['vehicle_model']} • ₹${calculateFare(cab).toInt()}",
              onTap: () => showBookingSheet(cab),
            ),
          );
        })
        .toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: markers.isNotEmpty
            ? markers.first.position
            : const LatLng(10.8505, 76.2711),
        zoom: 12,
      ),
      markers: markers,
      onMapCreated: (controller) {
        _mapController = controller;
        if (markers.isNotEmpty) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(markers.first.position),
          );
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
