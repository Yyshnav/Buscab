import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FeedbackPage(),
  ));
}

class FeedbackPage extends StatefulWidget {
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Sample feedback data
  List<Map<String, String>> feedbacks = [
    {
      "client": "John Doe",
      "date": "01-01-2026",
      "rating": "5",
      "message": "Excellent service, very punctual."
    },
    {
      "client": "Jane Smith",
      "date": "02-01-2026",
      "rating": "4",
      "message": "Good ride but bike was a little dirty."
    },
    {
      "client": "Mike Johnson",
      "date": "02-01-2026",
      "rating": "5",
      "message": "Smooth ride, will book again."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Feedback",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: feedbacks.isEmpty
          ? Center(child: Text("No feedback received yet"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                var fb = feedbacks[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Client: ${fb['client']}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text("Date: ${fb['date']}"),
                        SizedBox(height: 4),
                        Text("Rating: ${fb['rating']} ⭐"),
                        SizedBox(height: 8),
                        Text("Feedback:"),
                        Text(
                          "${fb['message']}",
                          style: TextStyle(color: Colors.grey.shade800),
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
