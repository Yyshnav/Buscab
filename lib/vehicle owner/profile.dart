import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:ridesync/user/login.dart';

class VehicleOwnerProfilePage extends StatefulWidget {
  @override
  State<VehicleOwnerProfilePage> createState() =>
      _VehicleOwnerProfilePageState();
}

class _VehicleOwnerProfilePageState extends State<VehicleOwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => _logout(),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const loginscreen()),
        (route) => false,
      );
    }
  }

  // Profile Info
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
            _nameController.text = data['name'] ?? "";
            _emailController.text = data['email'] ?? "";
            _phoneController.text = data['mobile_number']?.toString() ?? "";
            _licenseController.text = data['driving_licence'] ?? "";
            _adharController.text = data['aadhaar_number']?.toString() ?? "";
            _vehicleNoController.text = data['Vehicle_no'] ?? "";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
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
          "mobile_number": int.tryParse(_phoneController.text),
          "driving_licence": _licenseController.text,
          "aadhaar_number": int.tryParse(_adharController.text),
          "Vehicle_no": _vehicleNoController.text,
        };

        final response = await ApiService.updateOwnerProfile(loginId, data);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Name", _nameController),
                    _buildTextField(
                      "Email",
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      "Phone",
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      "Driving Licence Number",
                      _licenseController,
                    ),
                    _buildTextField("Vehicle Number", _vehicleNoController),
                    _buildTextField(
                      "Aadhaar Number",
                      _adharController,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                        onPressed: _submitProfile,
                        child: const Text(
                          "Update Profile",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "Please enter $label";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: isRequired ? "$label (Required)" : label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
