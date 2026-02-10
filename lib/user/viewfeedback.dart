import 'package:flutter/material.dart';
import 'package:ridesync/api/api_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Feedback",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: ApiService.getAllFeedbacks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No feedback received yet"));
          }

          final response = snapshot.data!;
          final List<dynamic> feeds = response.data ?? [];

          if (feeds.isEmpty) {
            return const Center(child: Text("No feedback received yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: feeds.length,
            itemBuilder: (context, index) {
              var fb = feeds[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Client: ${fb['user_id'] ?? 'Anonymous'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Rating: ${fb['rating'] ?? 'N/A'} ⭐"),
                      const SizedBox(height: 8),
                      const Text("Feedback:"),
                      Text(
                        "${fb['feedback'] ?? ''}",
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
