import 'package:flutter/material.dart';

class ViewFeedbackPage extends StatelessWidget {
  // Dummy feedback data (replace with backend later)
  final List<Map<String, dynamic>> feedbackList = [
    {
      "user": "Rahul",
      "feedback": "Very smooth ride and polite driver.",
      "rating": 5,
      "date": "01 Jan 2026"
    },
    {
      "user": "Anjali",
      "feedback": "Vehicle was clean but arrived a bit late.",
      "rating": 4,
      "date": "30 Dec 2025"
    },
    {
      "user": "Akhil",
      "feedback": "Good service, will book again!",
      "rating": 5,
      "date": "28 Dec 2025"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: Text(
          "User Feedback",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: feedbackList.isEmpty
          ? Center(
              child: Text(
                "No feedback available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = feedbackList[index];

                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User & Date
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text(
                              feedback["user"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Spacer(),
                            Text(
                              feedback["date"],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // ⭐ Rating Row
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < feedback["rating"]
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),

                        SizedBox(height: 10),

                        // Feedback text
                        Text(
                          feedback["feedback"],
                          style: TextStyle(fontSize: 14),
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
