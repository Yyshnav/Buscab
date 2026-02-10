import 'package:flutter/material.dart';
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
          'username': email.text, // Using email as username
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const loginscreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Registration Failed: $e")));
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
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                          if (value.length != 10)
                            return "Enter valid 10-digit number";
                          return null;
                        },
                      ),

                      _buildTextField(
                        controller: email,
                        label: "Email",
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Enter email";
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value))
                            return "Enter a valid email address";
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: aadhaar,
                        label: "Aadhaar Number",
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Enter Aadhaar number";
                          if (!RegExp(r'^[0-9]{12}$').hasMatch(value))
                            return "Enter a valid 12-digit Aadhaar number";
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: licence,
                        label: "Driving Licence (Optional)",
                        icon: Icons.drive_eta,
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
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Enter password";
                          if (value.length < 8)
                            return "Password must be at least 8 characters";
                          return null;
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
                          if (value == null || value.isEmpty)
                            return "Confirm password";
                          if (value != password.text)
                            return "Passwords do not match";
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
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
        validator:
            validator ?? (value) => value!.isEmpty ? "Enter password" : null,
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
