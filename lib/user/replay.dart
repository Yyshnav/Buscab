import 'package:flutter/material.dart';

class ViewReplyPage extends StatelessWidget {
  // Example replies (replace with your backend data)
  final List<Map<String, String>> replies = [
    {
      "complaint": "App is crashing",
      "reply": "We are fixing the issue. Update coming soon."
    },
    {
      "complaint": "Network not working",
      "reply": "Please restart the router and try again."
    },
    {
      "complaint": "Payment failed",
      "reply": "Refund has been initiated."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View Replies"),
        backgroundColor: Colors.blue,
      ),

      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Complaint:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  replies[index]["complaint"] ?? "",
                  style: TextStyle(fontSize: 15),
                ),

                SizedBox(height: 12),

                Text(
                  "Reply:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  replies[index]["reply"] ?? "",
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
