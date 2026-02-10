import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
          final usertype = response.data['usertype'];
          final userId = response.data['id'];

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
              final internalPk = profileResponse.data['id'];
              await prefs.setInt('user_id', internalPk);
            }
          } catch (e) {
            print("Error fetching profile during login: $e");
          }

          if (usertype == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserHomePage()),
            );
          } else if ( usertype == 'vehicleowner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VehicleOwnerHomePage()),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed: Invalid credentials")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 28,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text("User"),
                            selected: _selectedRole == 'user',
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedRole = 'user';
                              });
                            },
                            selectedColor: Colors.blue.shade100,
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text("Vehicle Owner"),
                            selected: _selectedRole == 'owner',
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedRole = 'owner';
                              });
                            },
                            selectedColor: Colors.blue.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Username field
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextFormField(
                          controller: name,
                          validator: (value) =>
                              value!.isEmpty ? "Enter your username" : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.blue,
                            ),
                            labelText: "Username",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Password field
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextFormField(
                          controller: password,
                          obscureText: hidePassword,
                          validator: (value) =>
                              value!.isEmpty ? "Enter password" : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.blue,
                            ),
                            labelText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Navigate to registration
                      TextButton(
                        onPressed: () {
                          if (_selectedRole == 'user') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VehicleOwnerRegistrationPage(),
                              ),
                            );
                          }
                        },
                        child: Text(
                          _selectedRole == 'user'
                              ? "Don’t have an account? Register as User"
                              : "Don’t have an account? Register as Owner",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
