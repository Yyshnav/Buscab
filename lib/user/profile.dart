import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui';
import 'package:ridesync/user/login.dart';
import 'package:ridesync/theme/app_theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _adharController = TextEditingController();
  final List<TextEditingController> _vehicleControllers = [
    TextEditingController(),
  ];

  String idProofType = "Aadhaar Card";
  bool idProofUploaded = false;
  File? profileImageFile;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  int? currentLoginId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentLoginId = prefs.getInt('login_id');
      if (currentLoginId != null) {
        final response = await ApiService.getUserProfile(currentLoginId!);
        if (response.statusCode == 200) {
          final userData = response.data;
          setState(() {
            _nameController.text = (userData['name'] ?? '').toString();
            _emailController.text = (userData['email'] ?? '').toString();
            _phoneController.text = (userData['mobile_number'] ?? '')
                .toString();
            _licenseController.text = (userData['driving_licence'] ?? '')
                .toString();
            _adharController.text = (userData['aadhaar_number'] ?? '')
                .toString();
            final vehicleNo = userData['Vehicle_no'];
            if (vehicleNo != null && vehicleNo.toString().isNotEmpty) {
              _vehicleControllers[0].text = vehicleNo.toString();
            }
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'mobile_number': _phoneController.text,
        'driving_licence': _licenseController.text,
        'aadhaar_number': _adharController.text,
        'Vehicle_no': _vehicleControllers.isNotEmpty
            ? _vehicleControllers[0].text
            : '',
      };
      final response = await ApiService.updateUserProfile(
        currentLoginId!,
        data,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile details synchronized"),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadUserProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync failed: $e"),
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
            "Are you sure you want to sign out? Your session data will be cleared.",
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
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: Hero(
                                tag: 'profile_pic',
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppTheme.surface,
                                  backgroundImage: profileImageFile != null
                                      ? FileImage(profileImageFile!)
                                      : null,
                                  child: profileImageFile == null
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 60,
                                          color: Colors.white24,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: GestureDetector(
                            //     onTap: () async {
                            //       final XFile? image = await _picker.pickImage(
                            //         source: ImageSource.gallery,
                            //       );
                            //       if (image != null)
                            //         setState(
                            //           () => profileImageFile = File(image.path),
                            //         );
                            //     },
                            //     child: Container(
                            //       padding: const EdgeInsets.all(10),
                            //       decoration: const BoxDecoration(
                            //         color: AppTheme.primary,
                            //         shape: BoxShape.circle,
                            //       ),
                            //       child: const Icon(
                            //         Icons.camera_alt_rounded,
                            //         color: Colors.white,
                            //         size: 20,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
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
                          "Network ID: ${currentLoginId ?? '---'}",
                          style: AppTheme.darkTheme.textTheme.bodySmall,
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
                          _buildSectionHeader("IDENTITY CORE"),
                          const SizedBox(height: 16),
                          _buildField(
                            _nameController,
                            "Full Identity Label",
                            Icons.badge_outlined,
                          ),
                          _buildField(
                            _emailController,
                            "Digital Communication",
                            Icons.alternate_email_rounded,
                            type: TextInputType.emailAddress,
                          ),
                          _buildField(
                            _phoneController,
                            "Contact Synchrony",
                            Icons.phone_android_rounded,
                            type: TextInputType.phone,
                          ),

                          const SizedBox(height: 32),
                          _buildSectionHeader("VERIFICATION PROTOCOL"),
                          const SizedBox(height: 16),
                          _buildField(
                            _adharController,
                            "Governing ID (Aadhaar)",
                            Icons.fingerprint_rounded,
                            type: TextInputType.number,
                          ),
                          _buildField(
                            _licenseController,
                            "Transit Authority Permit",
                            Icons.drive_eta_outlined,
                          ),

                          const SizedBox(height: 32),
                          _buildSectionHeader("ASSET REGISTRY"),
                          const SizedBox(height: 16),
                          ..._vehicleControllers.asMap().entries.map((entry) {
                            return _buildField(
                              entry.value,
                              "Primary Transit Unit",
                              Icons.local_shipping_outlined,
                            );
                          }),

                          const SizedBox(height: 48),
                          ElevatedButton(
                            onPressed: _submitProfile,
                            child: const Text("SYNCHRONIZE CORE DATA"),
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
