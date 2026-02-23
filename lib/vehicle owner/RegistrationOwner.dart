import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/user/login.dart';

class VehicleOwnerRegistrationPage extends StatefulWidget {
  const VehicleOwnerRegistrationPage({super.key});

  @override
  State<VehicleOwnerRegistrationPage> createState() =>
      _VehicleOwnerRegistrationPageState();
}

class _VehicleOwnerRegistrationPageState
    extends State<VehicleOwnerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void registerOwner() async {
    if (_formKey.currentState!.validate()) {
      try {
        final data = {
          'username': _emailController.text,
          'password': _passwordController.text,
          'usertype': 'vehicleowner',
          'name': _nameController.text,
          'mobile_number': int.parse(_phoneController.text),
          'email': _emailController.text,
          'driving_licence': '',
          'aadhaar_number': 0,
          'Vehicle_no': '',
        };

        final response = await ApiService.registerOwner(data);
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Partnership initialized! Welcome Provider."),
                backgroundColor: AppTheme.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const loginscreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration Error: $e"),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          ),
          Positioned(
            top: -100,
            right: -100,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.05),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 4.seconds, end: const Offset(1.2, 1.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.5, end: 0),

                    const SizedBox(height: 20),

                    Text(
                          "Partner Sign Up",
                          style: AppTheme.darkTheme.textTheme.displayLarge,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    Text(
                      "Register your vehicle and start earning",
                      style: AppTheme.darkTheme.textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    _buildSectionHeader("PERSONAL DETAILS"),
                    const SizedBox(height: 16),
                    _buildField(
                      _nameController,
                      "Full Name / Company Name",
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _emailController,
                      "Email Address",
                      Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _phoneController,
                      "Phone Number",
                      Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("SECURITY"),
                    const SizedBox(height: 16),
                    _buildField(
                      _passwordController,
                      "Password",
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      isObscured: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _confirmPasswordController,
                      "Confirm Password",
                      Icons.lock_reset_rounded,
                      isPassword: true,
                      isObscured: _obscureConfirmPassword,
                      onToggle: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      validator: (val) {
                        if (val != _passwordController.text)
                          return "Keys do not match";
                        return null;
                      },
                    ),

                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: registerOwner,
                      child: const Text("REGISTER"),
                    ).animate().fadeIn(delay: 400.ms).scale(),

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "ALREADY HAVE AN ACCOUNT? LOGIN",
                          style: AppTheme.darkTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                        ),
                      ),
                    ),
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
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggle,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      validator:
          validator ??
          (val) {
            if (isRequired && (val == null || val.isEmpty))
              return "Required field";
            return null;
          },
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
