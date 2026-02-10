import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';

class ViewFeedbackPage extends StatefulWidget {
  @override
  State<ViewFeedbackPage> createState() => _ViewFeedbackPageState();
}

class _ViewFeedbackPageState extends State<ViewFeedbackPage> {
  List<dynamic> feedbacks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      if (loginId != null) {
        final response = await ApiService.getOwnerFeedback(loginId);
        if (response.statusCode == 200) {
          setState(() {
            feedbacks = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching feedback: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "User Feedback & Ratings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : feedbacks.isEmpty
          ? const Center(child: Text("No feedback received yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                var feedback = feedbacks[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              feedback['student_name'] ?? "Anonymous User",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              feedback['date'] ?? "",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  color: i < (feedback['rating'] ?? 0)
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${feedback['rating']})",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "REVIEW:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback['review'] != null &&
                                  feedback['review'].isNotEmpty
                              ? feedback['review']
                              : "No detailed comment provided",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle:
                                feedback['review'] != null &&
                                    feedback['review'].isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                            color:
                                feedback['review'] != null &&
                                    feedback['review'].isNotEmpty
                                ? Colors.black87
                                : Colors.grey,
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
