import 'package:flutter/material.dart';
import 'viewreplay.dart'; // Make sure this imports your ReplayPage

class ComplaintPagevehicle extends StatefulWidget {
  @override
  State<ComplaintPagevehicle> createState() => _ComplaintPagevehicleState();
}

class _ComplaintPagevehicleState extends State<ComplaintPagevehicle> {
  final _complaintController = TextEditingController();

  // Store complaints and admin replies
  List<Map<String, String>> complaints = [];

  // Simulated admin reply for demonstration
  Map<String, String> adminReplies = {
    "Bike not available on time": "We apologize for the inconvenience.",
    "Vehicle was dirty": "We'll ensure cleanliness next time.",
    "Payment issue": "Issue resolved. Please check your account."
  };

  void submitComplaint() {
    if (_complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your complaint")),
      );
      return;
    }

    setState(() {
      String complaintText = _complaintController.text;
      String reply = adminReplies[complaintText] ?? ""; // empty if no reply
      complaints.add({"complaint": complaintText, "reply": reply, "date": "02-01-2026"});
      _complaintController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Complaint submitted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Submit Complaint",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint Input
            TextFormField(
              controller: _complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Enter your complaint",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: submitComplaint,
                child: Text("Submit Complaint", style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: 20),
            
            // Navigation button to ReplayPage
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReplayPage(
                        // replays: complaints, // Pass the complaints list
                      ),
                    ),
                  );
                },
                child: Text("View Admin Replies", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
