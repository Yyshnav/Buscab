import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class Historypage extends StatefulWidget {
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

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final response = await ApiService.getOwnerBookings(loginId);
        setState(() {
          bookingHistory = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch history: $e")));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Accepted":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: Text(
          "Booking History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingHistory.isEmpty
          ? const Center(child: Text("No booking history"))
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookingHistory.length,
                itemBuilder: (context, index) {
                  var booking = bookingHistory[index];
                  String clientName = booking['user_details'] != null
                      ? booking['user_details']['name']
                      : "Unknown Client";
                  String pickup = booking['vehicle_no'] != null
                      ? booking['vehicle_no']['pickup_location']
                      : "Unknown";
                  String drop = booking['vehicle_no'] != null
                      ? booking['vehicle_no']['drop_location']
                      : "Unknown";

                  return Card(
                    color: Colors.blue.shade50,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Client: $clientName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Pickup: $pickup"),
                          Text("Drop: $drop"),
                          const SizedBox(height: 4),
                          Text(
                            "Date: ${booking['date']} | Time: ${booking['time']}",
                          ),
                          if (booking['total_amount'] != null)
                            Text(
                              "Amount: ₹${booking['total_amount'].toString()}",
                            ),
                          const SizedBox(height: 6),
                          Text(
                            "Status: ${booking['status'] ?? 'Pending'}",
                            style: TextStyle(
                              color: _getStatusColor(
                                booking['status'] ?? 'Pending',
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
