import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';

class ReplayPage extends StatefulWidget {
  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final response = await ApiService.getOwnerComplaints(loginId);
        if (response.statusCode == 200) {
          setState(() {
            complaints = response.data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching complaints: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          "ADMIN REPLIES",
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
          : complaints.isEmpty
              ? _buildEmptyState()
              : _buildComplaintList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: AppTheme.textDim.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No complaints or replies found",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        var item = complaints[index];
        bool hasReply = item['replay'] != null && item['replay'].isNotEmpty;

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (hasReply ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasReply ? "RESOLVED" : "PENDING",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: hasReply ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ),
                  Text(
                    item['date'] ?? "",
                    style: TextStyle(color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "YOUR COMPLAINT",
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                "${item['complaint']}",
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10, height: 1),
              ),
              const Text(
                "ADMIN RESPONSE",
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                hasReply ? "${item['replay']}" : "Your ticket is being reviewed by our team.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: hasReply ? Colors.greenAccent.withOpacity(0.8) : Colors.white24,
                  fontStyle: hasReply ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
    
  }

