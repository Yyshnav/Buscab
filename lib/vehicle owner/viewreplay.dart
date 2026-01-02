import 'package:flutter/material.dart';



class ReplayPage extends StatelessWidget {
 
  // Sample complaint replays from admin
  List<Map<String, String>> replays = [
    {
      "complaint": "Bike not available on time",
      "reply": "We apologize for the inconvenience. We'll ensure timely service next time.",
      "date": "01-01-2026"
    },
    {
      "complaint": "Vehicle was dirty",
      "reply": "Thank you for the feedback. We'll maintain cleanliness in future rides.",
      "date": "03-01-2026"
    },
    {
      "complaint": "Payment issue",
      "reply": "Issue resolved. Please check your account for confirmation.",
      "date": "04-01-2026"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Admin Replies",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: replays.isEmpty
          ? Center(child: Text("No replies from admin yet"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: replays.length,
              itemBuilder: (context, index) {
                var replay = replays[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Complaint:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("${replay['complaint']}"),
                        SizedBox(height: 8),
                        Text(
                          "Admin Reply:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("${replay['reply']}"),
                        SizedBox(height: 8),
                        Text(
                          "Date: ${replay['date']}",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
