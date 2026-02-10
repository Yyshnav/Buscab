import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';

// ---------------- Booking Requests Page ----------------
class BookingRequestsPage extends StatefulWidget {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking ${status.toLowerCase()} successfully"),
          ),
        );
        _fetchBookings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update booking status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Booking Requests",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: bookings.isEmpty
                      ? const Center(child: Text("No booking requests"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            var booking = bookings[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status: ${booking['status']}",
                                      style: TextStyle(
                                        color: booking['status'] == "Pending"
                                            ? Colors.orange
                                            : (booking['status'] == "Accepted"
                                                  ? Colors.green
                                                  : Colors.red),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Vehicle: ${booking['vehicle_no']['vehicle_no'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text("Date: ${booking['date'] ?? 'N/A'}"),
                                    Text("Time: ${booking['time'] ?? 'N/A'}"),
                                    Text(
                                      "Fare: ₹${booking['total_amount'] ?? '0'}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Request sent at: ${booking['bookingtime']}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (booking['status'] == "Pending")
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => _updateStatus(
                                              booking['id'],
                                              "Accepted",
                                            ),
                                            child: const Text(
                                              "Accept",
                                              style: TextStyle(
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _updateStatus(
                                              booking['id'],
                                              "Rejected",
                                            ),
                                            child: const Text(
                                              "Reject",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      onPressed: () {
                        // Logic for history or detailed view if needed
                      },
                      child: const Text(
                        "Reload Requests",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- Booking History Page ----------------
class BookingHistoryPage extends StatelessWidget {
  // Sample booking history
  final List<Map<String, String>> history = [
    {
      "client": "John Doe",
      "pickup": "City Center",
      "drop": "Airport",
      "date": "01-01-2026",
      "time": "09:00 AM",
      "status": "Accepted",
    },
    {
      "client": "Jane Smith",
      "pickup": "Station",
      "drop": "Mall",
      "date": "31-12-2025",
      "time": "11:00 AM",
      "status": "Rejected",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Booking History",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: history.isEmpty
          ? Center(child: Text("No booking history"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                var booking = history[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Client: ${booking['client']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text("Pickup: ${booking['pickup']}"),
                        Text("Drop: ${booking['drop']}"),
                        Text(
                          "Date: ${booking['date']} | Time: ${booking['time']}",
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Status: ${booking['status']}",
                          style: TextStyle(
                            color: booking['status'] == "Accepted"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
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
}
