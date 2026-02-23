import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/user/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio;
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/vehicle owner/managevehicle.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LiftServiceHome extends StatefulWidget {
  const LiftServiceHome({super.key});

  @override
  State<LiftServiceHome> createState() => _LiftServiceHomeState();
}

class _LiftServiceHomeState extends State<LiftServiceHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> lifts = [];
  List<dynamic> myOfferedLifts = [];
  List<dynamic> incomingRequests = [];
  List<dynamic> myRequests = [];
  bool isLoading = true;
  bool isMyLiftsLoading = true;
  bool isRequestsLoading = true;
  int? currentLoginId;
  int? currentUserId;

  final TextEditingController _searchPickup = TextEditingController();
  final TextEditingController _searchDrop = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchPickup.dispose();
    _searchDrop.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadUser();
    _fetchLifts();
    await _fetchMyOfferedLifts();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLoginId = prefs.getInt('login_id');
      currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _fetchLifts() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final pickup = _searchPickup.text.trim().isEmpty
          ? null
          : _searchPickup.text.trim();
      final drop = _searchDrop.text.trim().isEmpty
          ? null
          : _searchDrop.text.trim();
      final response = await ApiService.getLifts(
        excludeUserId: userId,
        pickup: pickup,
        drop: drop,
      );
      if (response.statusCode == 200) {
        setState(() {
          lifts = response.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchMyOfferedLifts() async {
    setState(() => isMyLiftsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final response = await ApiService.getLifts(userId: userId);
        if (response.statusCode == 200) {
          setState(() {
            myOfferedLifts = response.data ?? [];
            isMyLiftsLoading = false;
          });
          await _fetchRequests();
        }
      } else {
        setState(() => isMyLiftsLoading = false);
      }
    } catch (e) {
      setState(() => isMyLiftsLoading = false);
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => isRequestsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final myReqRes = await ApiService.getMyLiftRequests(loginId);
        if (myReqRes.statusCode == 200)
          setState(() => myRequests = myReqRes.data);

        List<dynamic> allIncoming = [];
        for (var lift in myOfferedLifts) {
          if (lift['id'] != null) {
            final incRes = await ApiService.getIncomingLiftRequests(lift['id']);
            if (incRes.statusCode == 200 && incRes.data != null)
              allIncoming.addAll(incRes.data);
          }
        }
        setState(() => incomingRequests = allIncoming);
      }
      setState(() => isRequestsLoading = false);
    } catch (e) {
      setState(() => isRequestsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          "LIFTS",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white24,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: "FIND LIFT"),
            Tab(text: "MY LIFTS"),
            Tab(text: "MY REQUESTS"),
            Tab(text: "OFFER LIFT"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableTab(),
          _buildMyOffersTab(),
          _buildMyRequestsTab(),
          _buildOfferFormTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSearchField(
                      _searchPickup,
                      "From",
                      Icons.radio_button_checked_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSearchField(
                      _searchDrop,
                      "To",
                      Icons.location_on_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _fetchLifts,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text(
                    "SEARCH",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 11,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchLifts,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : lifts.isEmpty
                ? _buildEmptyState("No lifts found.")
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: lifts.length,
                    itemBuilder: (context, index) => _buildLiftCard(
                      lifts[index],
                      isAvailable: true,
                      index: index,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyOffersTab() {
    return RefreshIndicator(
      onRefresh: _fetchMyOfferedLifts,
      child: isMyLiftsLoading
          ? const Center(child: CircularProgressIndicator())
          : myOfferedLifts.isEmpty
          ? _buildEmptyState("You have no lifts posted yet.")
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myOfferedLifts.length,
              itemBuilder: (context, index) =>
                  _buildMyOfferCard(myOfferedLifts[index], index: index),
            ),
    );
  }

  Widget _buildMyRequestsTab() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: isRequestsLoading
          ? const Center(child: CircularProgressIndicator())
          : myRequests.isEmpty
          ? _buildEmptyState("No requests yet.")
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myRequests.length,
              itemBuilder: (context, index) =>
                  _buildRequestTrackingCard(myRequests[index], index: index),
            ),
    );
  }

  Widget _buildOfferFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ProvideLiftForm(
            onSuccess: () {
              _fetchMyOfferedLifts();
              _tabController.animateTo(1);
            },
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildSearchField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_clear_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textDim,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildLiftCard(
    dynamic lift, {
    required bool isAvailable,
    int index = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRouteRow(
                        Icons.radio_button_checked_rounded,
                        lift['pickup_location'],
                        AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildRouteRow(
                        Icons.location_on_rounded,
                        lift['drop_location'],
                        AppTheme.error,
                      ),
                    ],
                  ),
                ),
                if (isAvailable)
                  ElevatedButton(
                    onPressed: () => _handleRequest(lift['id']),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      "JOIN",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactInfo(
                  Icons.person_3_outlined,
                  lift['user_details']?['name'] ?? 'Driver',
                ),
                _buildCompactInfo(
                  Icons.chair_alt_rounded,
                  "${lift['seats']} Seats",
                ),
                _buildCompactInfo(Icons.timer_outlined, lift['time'] ?? 'TBD'),
              ],
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        lift['verification_status'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(
                          lift['verification_status'],
                        ).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      (lift['verification_status'] ?? 'PENDING').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(lift['verification_status']),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              if (lift['verification_status'] == 'rejected' &&
                  lift['rejection_reason'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Reason: ${lift['rejection_reason']}",
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return AppTheme.error;
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _buildMyOfferCard(dynamic lift, {int index = 0}) {
    final requests = incomingRequests
        .where((r) => r['lift'] == lift['id'])
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildLiftCard(lift, isAvailable: false, index: index),
          if (requests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "RIDE REQUESTS",
                  style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...requests.map((req) => _buildIncomingRequestItem(req)),
            const SizedBox(height: 10),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "No requests yet.",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildIncomingRequestItem(dynamic req) {
    bool isPending =
        (req['status'] ?? '').toString().toLowerCase() == 'pending';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.person_outline_rounded,
          color: AppTheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        req['user_details']?['name'] ?? 'Passenger',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "Seats: ${req['requested_seats']}",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: isPending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.greenAccent,
                  ),
                  onPressed: () => _updateStatus(req['id'], 'Accepted'),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.error,
                  ),
                  onPressed: () => _updateStatus(req['id'], 'Rejected'),
                ),
              ],
            )
          : Text(
              req['status'].toUpperCase(),
              style: TextStyle(
                color: req['status'] == 'Accepted'
                    ? Colors.greenAccent
                    : AppTheme.error,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
    );
  }

  Widget _buildRequestTrackingCard(dynamic req, {int index = 0}) {
    final lift = req['lift_details'];
    final status = (req['status'] ?? 'Pending').toString();
    Color statusColor = status == 'Accepted'
        ? Colors.greenAccent
        : (status == 'Rejected' ? AppTheme.error : Colors.orangeAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary,
                      child: const Icon(
                        Icons.electric_bolt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lift?['user_details']?['name'] ?? 'Driver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRouteRow(
              Icons.location_searching_rounded,
              lift?['pickup_location'],
              Colors.white24,
            ),
            const SizedBox(height: 8),
            _buildRouteRow(
              Icons.flag_rounded,
              lift?['drop_location'],
              Colors.white24,
            ),
            if (status == 'Accepted') ...[
              const Divider(height: 32, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📞 ${lift?['user_details']?['mobile_number'] ?? 'N/A'}",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showLiftFeedbackDialog(req),
                        icon: const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          "RATE",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showReportingOptions(lift),
                        icon: const Icon(
                          Icons.report_gmailerrorred_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        label: const Text(
                          "REPORT",
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRouteRow(IconData icon, dynamic text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Future<void> _handleRequest(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;
      final res = await ApiService.requestLift({
        'lift': id,
        'user': userId,
        'requested_seats': 1,
      });
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Request sent!"),
            backgroundColor: AppTheme.primary,
          ),
        );
        _fetchRequests();
        _tabController.animateTo(2);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showLiftFeedbackDialog(dynamic req) {
    double tempRating = 5.0;
    final feedbackController = TextEditingController();
    final vehicleDetails = req['lift_details']?['vehicle_details'];

    if (vehicleDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle info not available")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              title: Text(
                "Rate Your Lift",
                style: AppTheme.darkTheme.textTheme.headlineSmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "How was your ride with ${req['lift_details']?['user_details']?['name'] ?? 'Driver'}?",
                    style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < tempRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.orange,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            tempRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write your comments...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(color: AppTheme.textDim),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (currentUserId == null) throw "Session expired";

                      await ApiService.submitRating({
                        'login_id': currentUserId,
                        'vehicle_no': vehicleDetails['id'],
                        'rating': tempRating,
                        'review': feedbackController.text,
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Feedback submitted!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to submit: $e"),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
                  child: const Text("SUBMIT"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      final res = await ApiService.updateLiftRequestStatus(id, status);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $status"),
            backgroundColor: AppTheme.primary,
          ),
        );
        _fetchRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Action failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showReportingOptions(dynamic lift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "REPORT ISSUE",
              style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildReportOption(
              Icons.warning_amber_rounded,
              "Vehicle mismatch",
              () => _reportUser(lift, "Vehicle mismatch"),
            ),
            _buildReportOption(
              Icons.no_accounts_rounded,
              "Fake identity",
              () => _reportUser(lift, "Fake identity"),
            ),
            _buildReportOption(
              Icons.speed_rounded,
              "Unsafe driving",
              () => _reportUser(lift, "Unsafe driving"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.white10,
      ),
    );
  }

  Future<void> _reportUser(dynamic lift, String reason) async {
    Navigator.pop(context);
    try {
      if (currentUserId == null) throw "Session expired";

      final reportedUserId = lift['user_details']?['id'];
      if (reportedUserId == null) throw "Cannot identify user to report";

      await ApiService.submitComplaint({
        'login_id': currentUserId,
        'reported_user': reportedUserId,
        'complaint': reason,
        'complaint_type': 'Lift Report',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted. We will look into it."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report failed: $e"),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }
}

class ProvideLiftForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const ProvideLiftForm({super.key, required this.onSuccess});

  @override
  State<ProvideLiftForm> createState() => _ProvideLiftFormState();
}

class _ProvideLiftFormState extends State<ProvideLiftForm> {
  final pickup = TextEditingController();
  final drop = TextEditingController();
  final vehicleNo = TextEditingController();
  final seats = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? rcImage;
  bool isSubmitting = false;

  List<dynamic> savedVehicles = [];
  String? savedLicense;
  bool isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final vRes = await ApiService.getVehicles(loginId: loginId);
        if (vRes.statusCode == 200) {
          savedVehicles = vRes.data;
        }
      }
      if (loginId != null) {
        final pRes = await ApiService.getUserProfile(loginId);
        if (pRes.statusCode == 200) {
          savedLicense = pRes.data['driving_licence'];
        }
      }
    } catch (e) {
      print("Error loading saved data: $e");
    } finally {
      if (mounted) setState(() => isLoadingSaved = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        rcImage = File(picked.path);
      });
    }
  }

  void _selectVehicle(dynamic vehicle) {
    setState(() {
      vehicleNo.text = vehicle['vehicle_no'] ?? '';
      seats.text = (vehicle['seating_capacity'] ?? '').toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "OFFER A LIFT",
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (savedVehicles.isNotEmpty) ...[
            Text(
              "SELECT YOUR VEHICLE",
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textDim,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: savedVehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final v = savedVehicles[index];
                  bool isSelected = vehicleNo.text == v['vehicle_no'];
                  final String status = v['verification_status'] ?? 'pending';
                  final bool isRejected = status == 'rejected';

                  return GestureDetector(
                    onTap: () {
                      if (isRejected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "This vehicle is rejected. Please go to 'My Vehicles' to resubmit.",
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                      _selectVehicle(v);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isRejected ? AppTheme.error : AppTheme.primary)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isRejected
                                    ? AppTheme.error.withOpacity(0.3)
                                    : Colors.white10),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRejected)
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            if (isRejected) const SizedBox(width: 8),
                            Text(
                              v['vehicle_no'] ?? 'Vehicle',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isRejected
                                          ? AppTheme.error
                                          : Colors.white70),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (savedVehicles.any(
              (v) => v['verification_status'] == 'rejected',
            ))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VehicleManagementPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.settings_suggest_rounded,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  label: const Text(
                    "RESUBMIT REJECTED VEHICLE",
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
          _buildField(pickup, "FROM", Icons.radio_button_checked_rounded),
          _buildField(drop, "TO", Icons.location_on_rounded),
          _buildField(vehicleNo, "VEHICLE NUMBER", Icons.numbers_rounded),
          _buildField(
            seats,
            "SEATS",
            Icons.chair_alt_rounded,
            type: TextInputType.number,
          ),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  selectedDate == null
                      ? "SELECT DATE"
                      : "${selectedDate!.day}/${selectedDate!.month}",
                  Icons.calendar_today_rounded,
                  () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      initialDate: DateTime.now(),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  selectedTime == null
                      ? "SELECT TIME"
                      : selectedTime!.format(context),
                  Icons.access_time_rounded,
                  () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setState(() => selectedTime = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (savedLicense != null && savedLicense!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LICENSE VERIFIED",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "Your driving license is on file.",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "LICENSE REQUIRED",
                    style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Please add your driving license to your profile before offering a lift.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(),
                        ),
                      ).then((_) => _loadSavedData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    child: const Text(
                      "GO TO PROFILE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // RC Image Picker
          Text(
            "VEHICLE RC (REGISTRATION CERTIFICATE)",
            style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textDim,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: rcImage != null
                      ? AppTheme.primary.withOpacity(0.5)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: rcImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(rcImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "UPLOAD RC PHOTO",
                          style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "POST LIFT",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    bool hasLicense = (savedLicense != null && savedLicense!.isNotEmpty);
    if (selectedDate == null ||
        selectedTime == null ||
        pickup.text.isEmpty ||
        drop.text.isEmpty ||
        !hasLicense) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and add your license."),
        ),
      );
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final dateStr =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

      dio.FormData formData = dio.FormData.fromMap({
        'login_id': userId.toString(),
        'vehicle_no': vehicleNo.text,
        'pickup_location': pickup.text,
        'drop_location': drop.text,
        'seats': (int.tryParse(seats.text) ?? 1).toString(),
        'date': dateStr,
        'time': timeStr,
      });

      formData.fields.add(MapEntry('driving_licence', savedLicense!));

      if (rcImage != null) {
        formData.files.add(
          MapEntry(
            'rc_image',
            await dio.MultipartFile.fromFile(
              rcImage!.path,
              filename: rcImage!.path.split('/').last,
            ),
          ),
        );
      }

      final res = await ApiService.offerLift(formData);
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lift posted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to post lift. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }
}
