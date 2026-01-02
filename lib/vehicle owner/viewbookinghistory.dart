import 'package:flutter/material.dart';



class Historypage extends StatefulWidget {
  @override
  State<Historypage> createState() => _HistorypageState();
}

class _HistorypageState extends State<Historypage> {
  // Sample booking history data
  List<Map<String, String>> bookingHistory = [
    {
      "client": "John Doe",
      "pickup": "City Center",
      "drop": "Airport",
      "date": "28-12-2025",
      "time": "10:00 AM",
      "status": "Accepted"
    },
    {
      "client": "Jane Smith",
      "pickup": "Station",
      "drop": "Mall",
      "date": "29-12-2025",
      "time": "02:00 PM",
      "status": "Rejected"
    },
    {
      "client": "Michael Johnson",
      "pickup": "University",
      "drop": "Hotel",
      "date": "30-12-2025",
      "time": "11:30 AM",
      "status": "Accepted"
    },
  ];

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
      // Blue AppBar with centered title
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Booking History",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: bookingHistory.isEmpty
          ? Center(child: Text("No booking history"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: bookingHistory.length,
              itemBuilder: (context, index) {
                var booking = bookingHistory[index];
                return Card(
                  color: Colors.blue.shade50,
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
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text("Pickup: ${booking['pickup']}"),
                        Text("Drop: ${booking['drop']}"),
                        SizedBox(height: 4),
                        Text("Date: ${booking['date']} | Time: ${booking['time']}"),
                        SizedBox(height: 6),
                        Text(
                          "Status: ${booking['status']}",
                          style: TextStyle(
                            color: _getStatusColor(booking['status']!),
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
