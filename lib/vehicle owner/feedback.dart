import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';

class ViewFeedbackPage extends StatefulWidget {
  const ViewFeedbackPage({super.key});

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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          "SERVICE RATINGS",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : feedbacks.isEmpty
          ? _buildEmptyState()
          : _buildFeedbackList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 64,
            color: AppTheme.textDim.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No feedback received yet",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        var feedback = feedbacks[index];
        return _buildFeedbackCard(feedback, index);
      },
    );
  }

  Widget _buildFeedbackCard(dynamic feedback, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback['student_name'] ?? "Anonymous User",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                feedback['date'] ?? "",
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < (feedback['rating'] ?? 0)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < (feedback['rating'] ?? 0)
                        ? Colors.orangeAccent
                        : Colors.white10,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${feedback['rating'] ?? 0}/5",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Text(
            (feedback['review'] != null && feedback['review'].isNotEmpty)
                ? feedback['review']
                : "No detailed comment provided",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle:
                  (feedback['review'] != null && feedback['review'].isNotEmpty)
                  ? FontStyle.normal
                  : FontStyle.italic,
              color:
                  (feedback['review'] != null && feedback['review'].isNotEmpty)
                  ? Colors.white70
                  : Colors.white30,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}
