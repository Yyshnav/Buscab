import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/user/Registration.dart';
import 'package:ridesync/vehicle owner/RegistrationOwner.dart';
import 'package:ridesync/user/home.dart';
import 'package:ridesync/vehicle owner/home.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class loginscreen extends StatefulWidget {
  const loginscreen({super.key});

  @override
  State<loginscreen> createState() => _loginscreenState();
}

class _loginscreenState extends State<loginscreen> {
  TextEditingController name = TextEditingController();
  TextEditingController password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool hidePassword = true;
  String _selectedRole = 'user'; // 'user' or 'owner'

  void _login() async {
    if (formKey.currentState!.validate()) {
      try {
        final response = await ApiService.login(name.text, password.text);
        if (response.statusCode == 200) {
          final usertype =
              response.data['usertype']; // Backend returns 'user' or 'owner'
          final userId = response
              .data['login_id']; // Fixed: Backend returns 'login_id' not 'id'

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('login_id', userId);
          await prefs.setString('usertype', usertype);

          // Fetch User/Owner table ID (user_id)
          try {
            Response profileResponse;
            if (usertype == 'user') {
              profileResponse = await ApiService.getUserProfile(userId);
            } else {
              profileResponse = await ApiService.getOwnerProfile(userId);
            }

            if (profileResponse.statusCode == 200) {
              final internalPk = profileResponse
                  .data['id']; // This is the ID from Usertable/Ownertable
              await prefs.setInt('user_id', internalPk);
            }
          } catch (e) {
            debugPrint("Error fetching profile: $e");
          }

          if (mounted) {
            if (usertype == 'user') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserHomePage()),
              );
            } else if (usertype == 'owner') {
              // Backend returns 'owner'
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleOwnerHomePage(),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Invalid credentials. Access denied."),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
          // Animated Background
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          ),
          Positioned(
            top: -150,
            right: -100,
            child:
                Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.05),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 5.seconds,
                    ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.electric_bolt_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(delay: 200.ms),

                  const SizedBox(height: 32),

                  Text(
                        "CabSharing",
                        style: AppTheme.darkTheme.textTheme.displayLarge,
                      )
                      .animate()
                      .slideY(begin: 0.3, end: 0, duration: 600.ms)
                      .fadeIn(),

                  Text(
                    "Modern Transit Solutions",
                    style: AppTheme.darkTheme.textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 48),

                  // Role Selector
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        _buildRoleButton("user", "User", Icons.person_outline),
                        _buildRoleButton(
                          "owner",
                          "Driver / Owner",
                          Icons.local_taxi_outlined,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 32),

                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                              controller: name,
                              decoration: const InputDecoration(
                                hintText: "Username",
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  size: 20,
                                ),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? "Enter your username" : null,
                            )
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 20),

                        TextFormField(
                              controller: password,
                              obscureText: hidePassword,
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => hidePassword = !hidePassword,
                                  ),
                                ),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? "Enter your password" : null,
                            )
                            .animate()
                            .fadeIn(delay: 700.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 32),

                        ElevatedButton(
                              onPressed: _login,
                              child: const Text("LOGIN"),
                            )
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                            ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.outfit(
                                color: AppTheme.textDim,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_selectedRole == 'user') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegistrationScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          VehicleOwnerRegistrationPage(),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                "REGISTER",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1.seconds),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textDim,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppTheme.textDim,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
