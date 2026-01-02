import 'package:flutter/material.dart';
import 'package:ridesync/user/login.dart';

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
  final formKey = GlobalKey<FormState>();

  bool hidePassword = true;
  bool hideCPassword = true;

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
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: name,
                        label: "Full Name",
                        icon: Icons.person,
                        validator: (value) =>
                            value!.isEmpty ? "Enter your name" : null,
                      ),

                      _buildTextField(
                        controller: phone,
                        label: "Mobile Number",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) return "Enter your phone number";
                          if (value.length != 10) return "Enter valid 10-digit number";
                          return null;
                        },
                      ),

                      _buildTextField(
                        controller: email,
                        label: "Email",
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) return "Enter email";
                          if (!value.contains("@")) return "Enter a valid email";
                          return null;
                        },
                      ),

                      _buildPasswordField(
                        controller: password,
                        label: "Password",
                        hideText: hidePassword,
                        toggle: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),

                      _buildPasswordField(
                        controller: cpassword,
                        label: "Confirm Password",
                        hideText: hideCPassword,
                        toggle: () {
                          setState(() {
                            hideCPassword = !hideCPassword;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) return "Confirm password";
                          if (value != password.text) return "Passwords do not match";
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => loginscreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
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

  // --- CUSTOM UI FIELDS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool hideText,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: hideText,
        validator: validator ??
            (value) => value!.isEmpty ? "Enter password" : null,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock, color: Colors.blue),
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(
              hideText ? Icons.visibility_off : Icons.visibility,
              color: Colors.blue,
            ),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
