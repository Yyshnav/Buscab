import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/user/login.dart';
import 'package:ridesync/api/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController cpassword = TextEditingController();
  TextEditingController aadhaar = TextEditingController();
  TextEditingController licence = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool hidePassword = true;
  bool hideCPassword = true;

  void _register() async {
    if (formKey.currentState!.validate()) {
      try {
        final data = {
          'username': email.text,
          'password': password.text,
          'usertype': 'user',
          'name': name.text,
          'mobile_number': int.parse(phone.text),
          'email': email.text,
          'driving_licence': licence.text,
          'aadhaar_number': int.tryParse(aadhaar.text) ?? 0,
          'Vehicle_no': '',
        };

        final response = await ApiService.register(data);
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account created successfully! Welcome aboard."),
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
            bottom: -100,
            left: -100,
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
                key: formKey,
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
                          "Sign Up",
                          style: AppTheme.darkTheme.textTheme.displayLarge,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    Text(
                      "Fill in your details below",
                      style: AppTheme.darkTheme.textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    _buildSectionHeader("PERSONAL INFO"),
                    const SizedBox(height: 16),
                    _buildField(
                      name,
                      "Full Name",
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      phone,
                      "Phone Number",
                      Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      email,
                      "Email",
                      Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      aadhaar,
                      "Aadhaar Number",
                      Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("DOCUMENTS"),
                    const SizedBox(height: 16),
                    _buildField(
                      licence,
                      "Driving Licence",
                      Icons.drive_eta_outlined,
                      isRequired: false,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("SECURITY"),
                    const SizedBox(height: 16),
                    _buildField(
                      password,
                      "Password",
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      isObscured: hidePassword,
                      onToggle: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      cpassword,
                      "Confirm Password",
                      Icons.lock_reset_rounded,
                      isPassword: true,
                      isObscured: hideCPassword,
                      onToggle: () =>
                          setState(() => hideCPassword = !hideCPassword),
                      validator: (val) {
                        if (val != password.text) return "Keys do not match";
                        return null;
                      },
                    ),

                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: _register,
                      child: const Text("REGISTER"),
                    ).animate().fadeIn(delay: 400.ms).scale(),

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Already have an account? Login",
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
