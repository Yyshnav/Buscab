import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/user/login.dart';
import 'package:ridesync/theme/app_theme.dart';

class VehicleOwnerProfilePage extends StatefulWidget {
  const VehicleOwnerProfilePage({super.key});

  @override
  State<VehicleOwnerProfilePage> createState() =>
      _VehicleOwnerProfilePageState();
}

class _VehicleOwnerProfilePageState extends State<VehicleOwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _adharController = TextEditingController();
  final _vehicleNoController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final response = await ApiService.getOwnerProfile(loginId);
        if (response.statusCode == 200) {
          final data = response.data;
          setState(() {
            _nameController.text = (data['name'] ?? "").toString();
            _emailController.text = (data['email'] ?? "").toString();
            _phoneController.text = (data['mobile_number'] ?? "").toString();
            _licenseController.text = (data['driving_licence'] ?? "")
                .toString();
            _adharController.text = (data['aadhaar_number'] ?? "").toString();
            _vehicleNoController.text = (data['Vehicle_no'] ?? "").toString();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId != null) {
        final data = {
          "name": _nameController.text,
          "email": _emailController.text,
          "mobile_number": _phoneController.text,
          "driving_licence": _licenseController.text,
          "aadhaar_number": _adharController.text,
          "Vehicle_no": _vehicleNoController.text,
        };
        final response = await ApiService.updateOwnerProfile(loginId, data);
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account records synchronized"),
                backgroundColor: AppTheme.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Synchronization failed: $e"),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppTheme.surface.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            "Terminate Session?",
            style: AppTheme.darkTheme.textTheme.titleLarge,
          ),
          content: Text(
            "Confirm logout from Provider Portal. Session data will be cleared.",
            style: AppTheme.darkTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const loginscreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                "LOGOUT",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                onPressed: _showLogoutDialog,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.darkGradient,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.surface,
                            child: const Icon(
                              Icons.business_center_rounded,
                              size: 60,
                              color: Colors.white24,
                            ),
                          ),
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.bounceInOut,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.toUpperCase(),
                          style: AppTheme.darkTheme.textTheme.titleLarge
                              ?.copyWith(letterSpacing: 2),
                        ).animate().fadeIn(delay: 200.ms),
                        Text(
                          "Verified Provider",
                          style: AppTheme.darkTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.secondary),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(100),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("OPERATOR PROFILE"),
                          const SizedBox(height: 16),
                          _buildField(
                            _nameController,
                            "Legal Entity Name",
                            Icons.business_rounded,
                          ),
                          _buildField(
                            _emailController,
                            "Business Communication",
                            Icons.alternate_email_rounded,
                            type: TextInputType.emailAddress,
                          ),
                          _buildField(
                            _phoneController,
                            "Contact Network",
                            Icons.phone_android_rounded,
                            type: TextInputType.phone,
                          ),

                          const SizedBox(height: 32),
                          _buildSectionHeader("ASSET VERIFICATION"),
                          const SizedBox(height: 16),
                          _buildField(
                            _vehicleNoController,
                            "Primary Fleet Unit ID",
                            Icons.directions_car_filled_rounded,
                          ),
                          _buildField(
                            _licenseController,
                            "Operator Permit ID",
                            Icons.badge_outlined,
                          ),
                          _buildField(
                            _adharController,
                            "Aadhaar Identity Link",
                            Icons.fingerprint_rounded,
                            type: TextInputType.number,
                          ),

                          const SizedBox(height: 48),
                          ElevatedButton(
                            onPressed: _submitProfile,
                            child: const Text("SYNCHRONIZE PARTNER DATA"),
                          ).animate().fadeIn(delay: 400.ms).scale(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
        color: AppTheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ).animate().fadeIn();
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}
