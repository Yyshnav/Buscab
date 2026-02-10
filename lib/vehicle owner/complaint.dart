import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';

class ComplaintPagevehicle extends StatefulWidget {
  @override
  State<ComplaintPagevehicle> createState() => _ComplaintPagevehicleState();
}

class _ComplaintPagevehicleState extends State<ComplaintPagevehicle> {
  final _complaintController = TextEditingController();

  Future<void> _submitComplaint() async {
    if (_complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your complaint")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      if (loginId != null) {
        final data = {
          "complaint": _complaintController.text,
          "login_id": loginId,
          "replay": "",
        };

        final response = await ApiService.submitOwnerComplaint(data);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Complaint submitted successfully")),
          );
          _complaintController.clear();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit complaint")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Complaints",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint Input
            TextFormField(
              controller: _complaintController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Enter your complaint",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                onPressed: _submitComplaint,
                child: const Text(
                  "Submit Complaint",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
