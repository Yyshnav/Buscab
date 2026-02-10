import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:ridesync/user/login.dart';

class UserProfilePage extends StatefulWidget {
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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

  // Multiple vehicles
  List<TextEditingController> _vehicleControllers = [TextEditingController()];

  // ID Proof
  String idProofType = "Aadhaar Card";
  bool idProofUploaded = false;

  // Profile image
  File? profileImageFile;
  final ImagePicker _picker = ImagePicker();

  // Loading state
  bool isLoading = true;
  int? currentLoginId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('DEBUG: Starting to load user profile...');
    try {
      final prefs = await SharedPreferences.getInstance();
      currentLoginId = prefs.getInt('login_id');

      print(
        'DEBUG: Retrieved login_id from SharedPreferences: $currentLoginId',
      );

      if (currentLoginId != null) {
        print('DEBUG: Calling getUserProfile API with ID: $currentLoginId');
        final response = await ApiService.getUserProfile(currentLoginId!);

        print('DEBUG: API Response Status: ${response.statusCode}');
        print('DEBUG: API Response Data: ${response.data}');

        if (response.statusCode == 200) {
          final userData = response.data;
          print('DEBUG: User data received: $userData');

          setState(() {
            _nameController.text = (userData['name'] ?? '').toString();
            _emailController.text = (userData['email'] ?? '').toString();
            _phoneController.text = (userData['mobile_number'] ?? '')
                .toString();
            _licenseController.text = (userData['driving_licence'] ?? '')
                .toString();
            _adharController.text = (userData['aadhaar_number'] ?? '')
                .toString();

            // Handle vehicle number
            final vehicleNo = userData['Vehicle_no'];
            if (vehicleNo != null && vehicleNo.toString().isNotEmpty) {
              _vehicleControllers[0].text = vehicleNo.toString();
            }

            isLoading = false;
          });

          print('DEBUG: Profile data loaded successfully');
        } else {
          print('DEBUG: API returned non-200 status: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error: ${response.data}")));
          }
        }
      } else {
        print('DEBUG: No login_id found in SharedPreferences');
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to view profile")),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Exception in _loadUserProfile: $e');
      print('DEBUG: Exception stack trace: ${StackTrace.current}');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _adharController.dispose();
    for (var c in _vehicleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Pick profile image
  void _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImageFile = File(image.path);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile photo uploaded")));
    }
  }

  void _addVehicleField() {
    setState(() {
      _vehicleControllers.add(TextEditingController());
    });
  }

  void _removeVehicleField(int index) {
    if (_vehicleControllers.length > 1) {
      _vehicleControllers[index].dispose();
      setState(() {
        _vehicleControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (currentLoginId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to update profile")),
      );
      return;
    }

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

      print('DEBUG: Saving profile data: $data');
      print('DEBUG: Login ID: $currentLoginId');

      final response = await ApiService.updateUserProfile(
        currentLoginId!,
        data,
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Reload profile to confirm changes
          _loadUserProfile();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update: ${response.data}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                    // Profile Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImageFile != null
                          ? FileImage(profileImageFile!)
                          : null,
                      child: profileImageFile == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Text("Upload profile photo"),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        profileImageFile != null
                            ? "Change Profile Photo"
                            : "Upload Profile Photo",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      onPressed: _pickProfileImage,
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vehicle Numbers",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._vehicleControllers.asMap().entries.map((entry) {
                          int idx = entry.key;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  "Vehicle Number ${idx + 1}",
                                  entry.value,
                                ),
                              ),
                              if (_vehicleControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeVehicleField(idx),
                                ),
                            ],
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add Vehicle"),
                            onPressed: _addVehicleField,
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      "Aadhaar Number",
                      _adharController,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),

                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: idProofType,
                      decoration: const InputDecoration(
                        labelText: "Select ID Proof Type",
                        border: OutlineInputBorder(),
                      ),
                      items:
                          const [
                                "Aadhaar Card",
                                "Driving Licence",
                                "Passport",
                                "Voter ID",
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            idProofType = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        idProofUploaded ? "$idProofType ✅" : idProofType,
                      ), // just show label, no image
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      onPressed: () async {
                        // pick ID proof but do nothing else with image
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            idProofUploaded = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$idProofType uploaded")),
                          );
                        }
                      },
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
                          "Save Profile",
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
