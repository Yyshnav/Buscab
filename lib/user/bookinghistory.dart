import 'package:flutter/material.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/user/track_cab.dart';
import 'package:ridesync/user/payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final response = await ApiService.getUserBookings(userId);
        if (response.statusCode == 200) {
          setState(() {
            bookings = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load bookings: $e")));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
      case 'Completed':
      case 'Paid':
        return Colors.greenAccent;
      case 'Pending':
        return Colors.orangeAccent;
      case 'Rejected':
        return AppTheme.error;
      default:
        return AppTheme.textDim;
    }
  }

  void _showFeedbackDialog(dynamic booking) {
    double tempRating = 5.0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: Text(
            "Rate Your Ride",
            style: AppTheme.darkTheme.textTheme.headlineSmall,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How was your experience?",
                style: TextStyle(color: AppTheme.textDim, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < tempRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.orange,
                      size: 36,
                    ),
                    onPressed: () =>
                        setDialogState(() => tempRating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write your comments...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt('user_id');
                  if (userId == null) throw "Session expired";

                  final vehicleData = booking['vehicle_no'];
                  final vehicleId = vehicleData is Map
                      ? vehicleData['id']
                      : null;

                  await ApiService.submitRating({
                    'login_id': userId,
                    'vehicle_no': vehicleId,
                    'rating': tempRating,
                    'review': feedbackController.text,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Feedback submitted!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to submit: $e"),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text("SUBMIT"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          "MY BOOKINGS",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookingHistory,
        color: AppTheme.primary,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : bookings.isEmpty
            ? _buildEmptyState()
            : _buildBookingList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            "No bookings yet",
            style: TextStyle(color: AppTheme.textDim, fontSize: 15),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: bookings.length,
      itemBuilder: (context, index) =>
          _buildBookingCard(bookings[index], index),
    );
  }

  Widget _buildBookingCard(dynamic booking, int index) {
    final String status = booking['status'] ?? "Pending";
    final Color statusColor = _getStatusColor(status);
    final bool isAccepted = status == "Accepted";
    final bool isPaid = status == "Paid";

    final vehicleData = booking['vehicle_no'];
    final String vehicleNo = vehicleData is Map
        ? (vehicleData['vehicle_no'] ?? 'N/A')
        : 'N/A';
    final String vehicleModel = vehicleData is Map
        ? (vehicleData['vehicle_model'] ?? '')
        : '';
    final String pickup = vehicleData is Map
        ? (vehicleData['pickup_location'] ?? '')
        : '';
    final String drop = vehicleData is Map
        ? (vehicleData['drop_location'] ?? '')
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Main info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + amount row
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
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      "₹${booking['total_amount'] ?? '0'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicleNo,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      vehicleModel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // Route
                if (pickup.isNotEmpty || drop.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
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
                            "$pickup  →  $drop",
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

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                // Date & time
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

          // Action buttons row
          if (isAccepted || isPaid || status == "Completed")
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Payment Button (Only if Accepted)
                  if (isAccepted)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: () async {
                          final amount =
                              booking['total_amount']?.toDouble() ?? 0.0;
                          final refreshed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                bookingId: booking['id'],
                                amount: amount,
                              ),
                            ),
                          );
                          if (refreshed == true) {
                            _fetchBookingHistory();
                          }
                        },
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text(
                          "PAY",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withOpacity(0.1),
                          foregroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                  // Track Button
                  IconButton(
                    onPressed: () {
                      final vId = vehicleData is Map ? vehicleData['id'] : null;
                      if (vId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackCabPage(
                              vehicleId: vId,
                              vehicleNo: vehicleNo,
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primary,
                    ),
                    tooltip: "Track",
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showFeedbackDialog(booking),
                    icon: const Icon(Icons.star_rounded, color: Colors.orange),
                    tooltip: "Rate",
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
