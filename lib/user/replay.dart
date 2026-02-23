import 'package:flutter/material.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';

class ViewReplyPage extends StatefulWidget {
  const ViewReplyPage({super.key});

  @override
  State<ViewReplyPage> createState() => _ViewReplyPageState();
}

class _ViewReplyPageState extends State<ViewReplyPage> {
  List<dynamic> replies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  Future<void> _fetchReplies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final response = await ApiService.getComplaints(userId);
        if (response.statusCode == 200) {
          setState(() {
            replies = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching replies: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "SUPPORT TICKETS",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : replies.isEmpty
          ? _buildEmptyState()
          : _buildReplyList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_rounded,
            size: 64,
            color: AppTheme.textDim.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No active support tickets",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final item = replies[index];
        bool hasReply =
            item["replay"] != null &&
            item["replay"].toString().isNotEmpty &&
            item["replay"] != "Pending";

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hasReply
                  ? AppTheme.primary.withOpacity(0.2)
                  : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "INTEL REPORT",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    item["date"] ?? "",
                    style: TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item["complaint"] ?? "No details",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const Divider(color: Colors.white10, height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.reply_all_rounded,
                    size: 16,
                    color: hasReply ? Colors.greenAccent : AppTheme.textDim,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasReply
                              ? "RESPONSE TRANSMITTED"
                              : "AWAITING CLEARANCE",
                          style: TextStyle(
                            color: hasReply
                                ? Colors.greenAccent
                                : AppTheme.textDim,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasReply
                              ? item["replay"]
                              : "Command is reviewing your report. Status: Pending.",
                          style: TextStyle(
                            color: hasReply ? Colors.white : AppTheme.textDim,
                            fontSize: 14,
                            fontStyle: hasReply
                                ? FontStyle.normal
                                : FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
