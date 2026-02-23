import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:ridesync/theme/app_theme.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Fleet list state ──
  List<dynamic> _myVehicles = [];
  bool _loadingFleet = true;

  // ---------------- Basic Info ----------------
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();

  // ---------------- RC Details ----------------
  bool showRCDetails = false;
  String _vehicleClass = "MCWG";
  String fuelType = "Petrol";
  String cabType = "SUV";

  final List<String> cabTypes = ["SUV", "Hatchback", "Sedan", "MUV/MPV"];

  final _modelController = TextEditingController();
  final _seatingController = TextEditingController();
  final _rcExpiryController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _distanceKmController = TextEditingController();
  String rcFrontImage = "";
  String rcBackImage = "";
  String vehicleImage = "";

  // ---------------- Insurance Details ----------------
  bool showInsuranceDetails = false;
  final _insuranceProviderController = TextEditingController();
  final _policyNumberController = TextEditingController();
  String policyType = "Third Party";
  final _policyStartController = TextEditingController();
  final _policyExpiryController = TextEditingController();
  String insuranceDocImage = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyFleet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _modelController.dispose();
    _seatingController.dispose();
    _rcExpiryController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _perKmRateController.dispose();
    _distanceKmController.dispose();
    _insuranceProviderController.dispose();
    _policyNumberController.dispose();
    _policyStartController.dispose();
    _policyExpiryController.dispose();
    super.dispose();
  }

  // ── Fetch owner's fleet ──
  Future<void> _fetchMyFleet() async {
    setState(() => _loadingFleet = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final res = await ApiService.getVehicles(loginId: loginId);
        if (res.statusCode == 200) {
          setState(() => _myVehicles = res.data ?? []);
        }
      }
    } catch (e) {
      _showToast("Failed to load fleet: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _loadingFleet = false);
    }
  }

  // ── Delete vehicle ──
  Future<void> _deleteVehicle(int vehicleId, String vehicleNo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Remove Vehicle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove $vehicleNo from your fleet? This cannot be undone.",
          style: TextStyle(color: AppTheme.textDim, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "REMOVE",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.deleteVehicle(vehicleId);
      if (res.statusCode == 200) {
        _showToast("$vehicleNo removed from fleet", Colors.green);
        _fetchMyFleet();
      }
    } catch (e) {
      _showToast("Failed to remove vehicle: $e", Colors.red);
    }
  }

  // ── Resubmit vehicle ──
  void _resubmitVehicle(dynamic vehicle) {
    _vehicleNumberController.text = vehicle['vehicle_no'] ?? '';
    _ownerNameController.text = vehicle['owner_name'] ?? '';
    _pickupController.text = vehicle['pickup_location'] ?? '';
    _dropController.text = vehicle['drop_location'] ?? '';
    _perKmRateController.text = (vehicle['per_km_rate'] ?? 0.0).toString();
    _distanceKmController.text = (vehicle['distance_km'] ?? 0.0).toString();

    _modelController.text = vehicle['vehicle_model'] ?? '';
    _seatingController.text = (vehicle['seating_capacity'] ?? 4).toString();
    _rcExpiryController.text = vehicle['rc_expiry_date'] ?? '';
    _insuranceProviderController.text = vehicle['insurance_provider'] ?? '';
    _policyNumberController.text = vehicle['policy_number'] ?? '';

    setState(() {
      _vehicleClass = vehicle['vehicle_class'] ?? 'MCWG';
      fuelType = vehicle['fuel_type'] ?? 'Petrol';
      cabType = vehicle['cab_type'] ?? 'SUV';
      policyType = vehicle['policy_type'] ?? 'Third Party';
      _policyStartController.text = vehicle['policy_start_date'] ?? '';
      _policyExpiryController.text = vehicle['policy_expiry_date'] ?? '';
      showRCDetails = true;
      showInsuranceDetails = true;

      // Clear image paths as they need to be re-uploaded or we'd need more complex logic
      rcFrontImage = "";
      rcBackImage = "";
      insuranceDocImage = "";
      vehicleImage = "";
    });

    _tabController.animateTo(1);
    _showToast(
      "Please update your details and re-upload documents.",
      AppTheme.primary,
    );
  }

  bool _hasActiveVehicle() {
    return _myVehicles.any(
      (v) =>
          v['verification_status'] == 'pending' ||
          v['verification_status'] == 'approved',
    );
  }

  // ---------------- Helpers ----------------
  void toggleRCDetails() => setState(() => showRCDetails = !showRCDetails);
  void toggleInsuranceDetails() =>
      setState(() => showInsuranceDetails = !showInsuranceDetails);

  // ---------------- Image Picker ----------------
  void _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (type == "rcFront") rcFrontImage = pickedFile.path;
        if (type == "rcBack") rcBackImage = pickedFile.path;
        if (type == "insurance") insuranceDocImage = pickedFile.path;
        if (type == "vehicle") vehicleImage = pickedFile.path;
      });
    }
  }

  // ---------------- Date Picker Field ----------------
  Widget _buildDateField(String label, TextEditingController controller) {
    return _buildTextField(
      controller: controller,
      label: label,
      readOnly: true,
      icon: Icons.calendar_today_rounded,
      onTap: () async {
        DateTime? date = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2035),
          initialDate: DateTime.now(),
        );
        if (date != null) {
          controller.text =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        }
      },
    );
  }

  // ---------------- Upload Button ----------------
  Widget _buildUploadButton(String label, String type) {
    String status = "";
    if (type == "rcFront") status = rcFrontImage;
    if (type == "rcBack") status = rcBackImage;
    if (type == "insurance") status = insuranceDocImage;
    if (type == "vehicle") status = vehicleImage;

    bool hasImage = status.isNotEmpty;

    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(
          hasImage ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
          color: hasImage ? Colors.greenAccent : AppTheme.primary,
          size: 20,
        ),
        label: Text(
          hasImage ? "$label CONFIGURED" : "UPLOAD $label",
          style: TextStyle(
            color: hasImage ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: hasImage
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
          ),
          backgroundColor: hasImage
              ? Colors.greenAccent.withOpacity(0.05)
              : Colors.white.withOpacity(0.02),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _pickImage(type),
      ),
    ).animate(target: hasImage ? 1 : 0).shimmer(duration: 1.seconds);
  }

  // ---------------- Save Vehicle ----------------
  void saveVehicle() async {
    if (_vehicleNumberController.text.trim().isEmpty) {
      _showToast("Vehicle Number is required", Colors.orange);
      return;
    }

    final regExp = RegExp(
      r'^[A-Z]{2}\s?[0-9]{2}\s?[A-Z]{1,2}\s?[0-9]{4}$',
      caseSensitive: false,
    );
    if (!regExp.hasMatch(
      _vehicleNumberController.text.trim().replaceAll(' ', ''),
    )) {
      _showToast(
        "Invalid Vehicle Number format (e.g. KL 01 AB 1234)",
        Colors.orange,
      );
    }

    if (_ownerNameController.text.trim().isEmpty) {
      _showToast("Owner Name is required", Colors.orange);
      return;
    }

    if (_pickupController.text.isEmpty || _dropController.text.isEmpty) {
      _showToast(
        "Service locations (Pickup & Drop) are mandatory",
        Colors.orange,
      );
      return;
    }

    if (rcFrontImage.isEmpty ||
        rcBackImage.isEmpty ||
        insuranceDocImage.isEmpty) {
      _showToast(
        "All documents (RC Front, Back, Insurance) must be uploaded",
        Colors.redAccent,
      );
      return;
    }

    int seats = int.tryParse(_seatingController.text) ?? 0;
    if (seats <= 0 || seats > 50) {
      _showToast("Invalid Seating Capacity (1-50)", Colors.orange);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null || userId == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired. Please log in again."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final Map<String, dynamic> vehicleData = {
        'loginid': userId,
        'vehicle_no': _vehicleNumberController.text,
        'owner_name': _ownerNameController.text,
        'pickup_location': _pickupController.text,
        'drop_location': _dropController.text,
        'per_km_rate': double.tryParse(_perKmRateController.text) ?? 0.0,
        'distance_km': double.tryParse(_distanceKmController.text) ?? 0.0,
        'vehicle_class': _vehicleClass,
        'fuel_type': fuelType,
        'vehicle_model': _modelController.text,
        'seating_capacity': int.tryParse(_seatingController.text) ?? 4,
        'cab_type': cabType,
        'rc_expiry_date': _rcExpiryController.text.isNotEmpty
            ? _rcExpiryController.text
            : null,
        'insurance_provider': _insuranceProviderController.text,
        'policy_number': _policyNumberController.text,
        'policy_type': policyType,
        'policy_start_date': _policyStartController.text.isNotEmpty
            ? _policyStartController.text
            : null,
        'policy_expiry_date': _policyExpiryController.text.isNotEmpty
            ? _policyExpiryController.text
            : null,
        'latitude': 0.0,
        'longitude': 0.0,
      };

      final data = dio_lib.FormData.fromMap(vehicleData);

      if (rcFrontImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'rc_front_img',
            await dio_lib.MultipartFile.fromFile(rcFrontImage),
          ),
        );
      }
      if (rcBackImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'rc_back_img',
            await dio_lib.MultipartFile.fromFile(rcBackImage),
          ),
        );
      }
      if (insuranceDocImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'insurance_document',
            await dio_lib.MultipartFile.fromFile(insuranceDocImage),
          ),
        );
      }
      if (vehicleImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'vehicle_image',
            await dio_lib.MultipartFile.fromFile(vehicleImage),
          ),
        );
      }

      final response = await ApiService.addVehicle(data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showToast(
          response.statusCode == 201
              ? "Vehicle added to fleet!"
              : "Vehicle resubmitted successfully!",
          Colors.green,
        );
        _resetForm();
        _fetchMyFleet();
        _tabController.animateTo(0); // Switch to fleet tab
      }
    } catch (e) {
      String errorMsg = "Failed to save vehicle: $e";
      if (e is dio_lib.DioException && e.response?.statusCode == 400) {
        if (e.response.toString().contains("already registered")) {
          errorMsg = "Vehicle number already registered";
        } else {
          errorMsg = "Invalid Data: ${e.response?.data}";
        }
      }
      _showToast(errorMsg, Colors.red);
    }
  }

  void _resetForm() {
    _vehicleNumberController.clear();
    _ownerNameController.clear();
    _modelController.clear();
    _seatingController.clear();
    _rcExpiryController.clear();
    _pickupController.clear();
    _dropController.clear();
    _perKmRateController.clear();
    _distanceKmController.clear();
    _insuranceProviderController.clear();
    _policyNumberController.clear();
    _policyStartController.clear();
    _policyExpiryController.clear();
    setState(() {
      rcFrontImage = "";
      rcBackImage = "";
      vehicleImage = "";
      insuranceDocImage = "";
      showRCDetails = false;
      showInsuranceDetails = false;
    });
  }

  void _showToast(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          "MY VEHICLES",
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
            Tab(text: "VEHICLES"),
            Tab(text: "ADD NEW"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFleetTab(), _buildAddVehicleTab()],
      ),
    );
  }

  // ══════════════════════════════════════
  //  TAB 1: MY FLEET
  // ══════════════════════════════════════
  Widget _buildFleetTab() {
    if (_loadingFleet) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 20),
            Text(
              "No vehicles in your fleet yet.",
              style: TextStyle(color: AppTheme.textDim, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "ADD VEHICLE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyFleet,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myVehicles.length,
        itemBuilder: (context, index) =>
            _buildVehicleCard(_myVehicles[index], index),
      ),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, int index) {
    final hasRoute =
        (vehicle['pickup_location'] != null &&
            vehicle['pickup_location'].toString().isNotEmpty) ||
        (vehicle['drop_location'] != null &&
            vehicle['drop_location'].toString().isNotEmpty);

    final status = vehicle['verification_status'] ?? 'pending';
    final rejectionReason = vehicle['rejection_reason'];

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    Color statusBg;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981); // green
        statusBg = const Color(0xFF10B981);
        statusIcon = Icons.verified_rounded;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusBg = AppTheme.error;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = const Color(0xFFF59E0B); // amber
        statusBg = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Pending Review';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusBg.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          // Vehicle image if available
          if (vehicle['vehicle_image'] != null &&
              vehicle['vehicle_image'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                "${ApiService.baseUrl}${vehicle['vehicle_image']}",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vehicle['vehicle_no'] ?? 'N/A',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vehicle['vehicle_model'] ?? 'Unknown Model',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Delete button
                    IconButton(
                      onPressed: () => _deleteVehicle(
                        vehicle['id'],
                        vehicle['vehicle_no'] ?? 'this vehicle',
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      tooltip: "Remove Vehicle",
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.error.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Verification status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusBg.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(width: 8),
                        Text(
                          "— Awaiting admin verification",
                          style: TextStyle(
                            color: statusColor.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Rejection reason
                if (status == 'rejected' &&
                    rejectionReason != null &&
                    rejectionReason.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      "Reason: $rejectionReason",
                      style: TextStyle(
                        color: AppTheme.error.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Rejection actions
                if (status == 'rejected') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _resubmitVehicle(vehicle),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        "RESUBMIT VEHICLE",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Info chips row
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.local_gas_station_rounded,
                      vehicle['fuel_type'] ?? 'N/A',
                    ),
                    _buildInfoChip(
                      Icons.airline_seat_recline_normal_rounded,
                      "${vehicle['seating_capacity'] ?? '-'} seats",
                    ),
                    _buildInfoChip(
                      Icons.category_rounded,
                      vehicle['cab_type'] ?? 'N/A',
                    ),
                    _buildInfoChip(
                      Icons.currency_rupee_rounded,
                      vehicle['per_km_rate'] != null
                          ? "₹${vehicle['per_km_rate']}/km"
                          : 'Rate N/A',
                    ),
                  ],
                ),

                // Route badge
                if (hasRoute) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${vehicle['pickup_location'] ?? '?'}  →  ${vehicle['drop_location'] ?? '?'}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expanded details for "All data" transparency
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompactDetail(
                        "Vehicle Class",
                        vehicle['vehicle_class'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "Insurance Provider",
                        vehicle['insurance_provider'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "Policy Number",
                        vehicle['policy_number'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "Policy Type",
                        vehicle['policy_type'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "Policy Start",
                        vehicle['policy_start_date'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "Policy Expiry",
                        vehicle['policy_expiry_date'] ?? 'N/A',
                      ),
                      _buildCompactDetail(
                        "RC Expiry",
                        vehicle['rc_expiry_date'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),

                // Documents section for full visibility
                if (vehicle['rc_front_img'] != null ||
                    vehicle['rc_back_img'] != null ||
                    vehicle['insurance_document'] != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "SUBMITTED DOCUMENTS",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (vehicle['rc_front_img'] != null)
                          _buildDocMiniature(
                            "RC Front",
                            vehicle['rc_front_img'],
                          ),
                        if (vehicle['rc_back_img'] != null)
                          _buildDocMiniature("RC Back", vehicle['rc_back_img']),
                        if (vehicle['insurance_document'] != null)
                          _buildDocMiniature(
                            "Insurance",
                            vehicle['insurance_document'],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildDocMiniature(String label, String imagePath) {
    return GestureDetector(
      onTap: () => _viewLargeImage(imagePath, label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          image: DecorationImage(
            image: NetworkImage("${ApiService.baseUrl}$imagePath"),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _viewLargeImage(String imagePath, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                "${ApiService.baseUrl}$imagePath",
                loadingBuilder: (ctx, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textDim, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  //  TAB 2: ADD VEHICLE
  // ══════════════════════════════════════
  Widget _buildAddVehicleTab() {
    if (_hasActiveVehicle()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 80,
                color: AppTheme.primary.withOpacity(0.2),
              ),
              const SizedBox(height: 24),
              const Text(
                "REGISTRATION ACTIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You already have a vehicle submitted or approved. You don't need to submit again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => _tabController.animateTo(0),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    "VIEW MY FLEET",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Basic Info --------
          _buildSectionTitle("Basic Information"),
          _buildTextField(
            controller: _vehicleNumberController,
            label: "Vehicle Number",
            icon: Icons.numbers_rounded,
          ),
          const SizedBox(height: 12),
          _buildUploadButton("PHOTO", "vehicle"),

          const SizedBox(height: 12),
          _buildTextField(
            controller: _ownerNameController,
            label: "Owner Name",
            icon: Icons.person_3_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _pickupController,
            label: "Service From (Pickup)",
            icon: Icons.my_location_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _dropController,
            label: "Service To (Drop)",
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _perKmRateController,
            label: "Per KM Rate (₹)",
            keyboardType: TextInputType.number,
            icon: Icons.currency_rupee_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _distanceKmController,
            label: "Distance (KM)",
            keyboardType: TextInputType.number,
            icon: Icons.route_rounded,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // -------- RC Details Toggle --------
          _buildSectionHeader(
            "RC Information",
            showRCDetails,
            toggleRCDetails,
            Icons.article_rounded,
          ),
          if (showRCDetails)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildDropdown(
                    "Vehicle Class",
                    _vehicleClass,
                    ["MCWG", "MCWOG", "LMV-CAB", "LMV-NT"],
                    (v) => setState(() => _vehicleClass = v!),
                    Icons.category_rounded,
                  ),
                  if (_vehicleClass == "LMV-CAB") ...[
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Cab Type",
                      cabType,
                      cabTypes,
                      (v) => setState(() => cabType = v!),
                      Icons.airport_shuttle_rounded,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Fuel Type",
                    fuelType,
                    ["Petrol", "Diesel", "Electric", "CNG"],
                    (v) => setState(() => fuelType = v!),
                    Icons.local_gas_station_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _modelController,
                    label: "Vehicle Model",
                    icon: Icons.model_training_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _seatingController,
                    label: "Seating Capacity",
                    keyboardType: TextInputType.number,
                    icon: Icons.chair_alt_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField("RC Expiry Date", _rcExpiryController),
                  const SizedBox(height: 20),
                  _buildUploadButton("RC FRONT", "rcFront"),
                  const SizedBox(height: 12),
                  _buildUploadButton("RC BACK", "rcBack"),
                ],
              ).animate().fadeIn().slideY(begin: 0.05, end: 0),
            ),

          const SizedBox(height: 12),

          // -------- Insurance Details Toggle --------
          _buildSectionHeader(
            "Insurance Details",
            showInsuranceDetails,
            toggleInsuranceDetails,
            Icons.verified_user_rounded,
          ),
          if (showInsuranceDetails)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _insuranceProviderController,
                    label: "Insurance Provider",
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _policyNumberController,
                    label: "Policy Number",
                    icon: Icons.policy_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Policy Type",
                    policyType,
                    ["Third Party", "Comprehensive"],
                    (v) => setState(() => policyType = v!),
                    Icons.security_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField("Policy Start Date", _policyStartController),
                  const SizedBox(height: 12),
                  _buildDateField(
                    "Policy Expiry Date",
                    _policyExpiryController,
                  ),
                  const SizedBox(height: 20),
                  _buildUploadButton("INSURANCE DOC", "insurance"),
                ],
              ).animate().fadeIn().slideY(begin: 0.05, end: 0),
            ),

          const SizedBox(height: 32),

          // Save Button
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
                  onPressed: saveVehicle,
                  child: const Text(
                    "SAVE VEHICLE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ══════════ Helper Widgets ══════════
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isExpanded,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isExpanded
              ? AppTheme.primary.withOpacity(0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isExpanded ? AppTheme.primary : AppTheme.textDim,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isExpanded ? Colors.white : AppTheme.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textDim,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textDim, fontSize: 12),
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.primary, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textDim, fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
