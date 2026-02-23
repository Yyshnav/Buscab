import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';

class Historypage extends StatefulWidget {
  const Historypage({super.key});

  @override
  State<Historypage> createState() => _HistorypageState();
}

class _HistorypageState extends State<Historypage> {
  List<dynamic> bookingHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchBookingsWrapper() async {
    await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final response = await ApiService.getOwnerBookings(loginId);
        if (response.statusCode == 200) {
          setState(() {
            bookingHistory = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to fetch history: $e")));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Accepted":
        return Colors.greenAccent;
      case "Rejected":
        return AppTheme.error;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        centerTitle: true,
        title: Text(
          "TRIP LEDGER",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : bookingHistory.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _fetchBookingsWrapper,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: bookingHistory.length,
                itemBuilder: (context, index) {
                  var booking = bookingHistory[index];
                  String clientName =
                      booking['login_id'] is Map &&
                          booking['login_id']['name'] != null
                      ? booking['login_id']['name']
                      : "Unknown Client";

                  return _buildHistoryCard(booking, clientName, index);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppTheme.textDim.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No booking history found",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic booking, String clientName, int index) {
    final status = (booking['status'] ?? 'Pending').toString();
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
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
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppTheme.textDim,
              ),
              const SizedBox(width: 8),
              Text(
                "${booking['date']} • ${booking['time']}",
                style: TextStyle(color: AppTheme.textDim, fontSize: 13),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          if (booking['total_amount'] != null)
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee_rounded,
                  size: 16,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  "₹${booking['total_amount']}",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }
}
