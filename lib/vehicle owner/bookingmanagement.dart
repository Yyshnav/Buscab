import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BookingRequestsPage(),
  ));
}

// ---------------- Booking Requests Page ----------------
class BookingRequestsPage extends StatefulWidget {
  @override
  State<BookingRequestsPage> createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  // Sample booking requests
  List<Map<String, String>> bookings = [
    {
      "client": "John Doe",
      "pickup": "City Center",
      "drop": "Airport",
      "date": "02-01-2026",
      "time": "10:00 AM",
      "status": "Pending"
    },
    {
      "client": "Jane Smith",
      "pickup": "Station",
      "drop": "Mall",
      "date": "03-01-2026",
      "time": "02:00 PM",
      "status": "Pending"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Booking Requests",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: bookings.isEmpty
                ? Center(child: Text("No booking requests"))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      var booking = bookings[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Client: ${booking['client']}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Pickup: ${booking['pickup']}"),
                              Text("Drop: ${booking['drop']}"),
                              Text(
                                  "Date: ${booking['date']} | Time: ${booking['time']}"),
                              SizedBox(height: 8),
                              Text(
                                "Status: ${booking['status']}",
                                style: TextStyle(
                                    color: booking['status'] == "Pending"
                                        ? Colors.orange
                                        : (booking['status'] == "Accepted"
                                            ? Colors.green
                                            : Colors.red),
                                    fontWeight: FontWeight.bold),
                              ),
                              if (booking['status'] == "Pending")
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() =>
                                            bookings[index]['status'] = "Accepted");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Request accepted")),
                                        );
                                      },
                                      child: Text("Accept",
                                          style: TextStyle(color: Colors.green)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() =>
                                            bookings[index]['status'] = "Rejected");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Request rejected")),
                                        );
                                      },
                                      child: Text("Reject",
                                          style: TextStyle(color: Colors.red)),
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
          // -------- View Booking History Button --------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingHistoryPage()),
                  );
                },
                child: Text(
                  "View Booking History",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      "status": "Accepted"
    },
    {
      "client": "Jane Smith",
      "pickup": "Station",
      "drop": "Mall",
      "date": "31-12-2025",
      "time": "11:00 AM",
      "status": "Rejected"
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
                        Text("Client: ${booking['client']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Pickup: ${booking['pickup']}"),
                        Text("Drop: ${booking['drop']}"),
                        Text(
                            "Date: ${booking['date']} | Time: ${booking['time']}"),
                        SizedBox(height: 8),
                        Text(
                          "Status: ${booking['status']}",
                          style: TextStyle(
                              color: booking['status'] == "Accepted"
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold),
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
