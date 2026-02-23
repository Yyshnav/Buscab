import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/api/location_service.dart';
import 'package:ridesync/theme/app_theme.dart';

// ---------------- Booking Requests Page ----------------
class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({super.key});

  @override
  State<BookingRequestsPage> createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      if (loginId != null) {
        final response = await ApiService.getOwnerBookings(loginId);
        if (response.statusCode == 200) {
          setState(() {
            bookings = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching bookings: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(int bookingId, String status) async {
    try {
      final response = await ApiService.updateBookingStatus(bookingId, status);
      if (response.statusCode == 200) {
        if (status == "Accepted") {
          // Find the booking to get vehicle ID
          final booking = bookings.firstWhere((b) => b['id'] == bookingId);
          if (booking != null && booking['vehicle_no'] != null) {
            final vehicleId = booking['vehicle_no']['id'];
            if (vehicleId != null) {
              LocationService().startTracking(vehicleId);
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking ${status.toLowerCase()} successfully"),
            backgroundColor: status == "Accepted"
                ? Colors.greenAccent
                : AppTheme.error,
          ),
        );
        _fetchBookings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update booking status"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "BOOKINGS",
                style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _fetchBookings,
          color: AppTheme.primary,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : bookings.isEmpty
              ? _buildEmptyState()
              : _buildBookingList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchBookings,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: 64,
            color: AppTheme.textDim.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No bookings yet",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        var booking = bookings[index];
        return _buildBookingCard(booking, index);
      },
    );
  }

  Widget _buildBookingCard(dynamic booking, int index) {
    final String status = booking['status'] ?? "Pending";
    final bool isPending = status == "Pending";
    Color statusColor = status == "Accepted"
        ? Colors.greenAccent
        : (status == "Pending" ? Colors.orangeAccent : AppTheme.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      "₹${booking['total_amount'] ?? '0'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['login_id'] is Map
                                ? (booking['login_id']['name'] ?? 'Client')
                                      .toString()
                                : 'Client',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            booking['login_id'] is Map
                                ? (booking['login_id']['mobile_number'] ??
                                          'N/A')
                                      .toString()
                                : 'N/A',
                            style: TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.call_outlined,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                      onPressed: () {}, // TODO: Implement call
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                _buildInfoRow(
                  Icons.directions_car_filled_rounded,
                  "Vehicle",
                  booking['vehicle_no'] is Map
                      ? (booking['vehicle_no']['vehicle_no'] ?? 'N/A')
                            .toString()
                      : 'N/A',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.calendar_today_rounded,
                        "Date",
                        (booking['date'] ?? 'N/A').toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.access_time_rounded,
                        "Time",
                        (booking['time'] ?? 'N/A').toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateStatus(booking['id'], "Rejected"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "REJECT",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateStatus(booking['id'], "Accepted"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "ACCEPT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            color: AppTheme.textDim,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
