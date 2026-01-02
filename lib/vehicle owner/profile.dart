import 'package:flutter/material.dart';

class VehicleOwnerProfilePage extends StatefulWidget {
  @override
  State<VehicleOwnerProfilePage> createState() =>
      _VehicleOwnerProfilePageState();
}

class _VehicleOwnerProfilePageState extends State<VehicleOwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();

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
  bool profileUploaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _adharController.dispose();
    _vehicleControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  // Simulate profile image upload
  void _pickProfileImage() {
    setState(() {
      profileUploaded = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Profile photo uploaded")));
  }

  // Simulate ID proof upload
  void _pickIDProof() {
    setState(() {
      idProofUploaded = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$idProofType uploaded")));
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

  // Submit form with mandatory checks
  void _submitProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (!profileUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload a profile photo")));
      return;
    }

    if (_adharController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter your Aadhaar number")));
      return;
    }

    if (!idProofUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload your ID proof")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile submitted successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile avatar
              CircleAvatar(
                radius: 60,
                backgroundColor:
                    profileUploaded ? Colors.green.shade700 : Colors.blue.shade700,
                child: profileUploaded
                    ? Text("✅", style: TextStyle(fontSize: 40, color: Colors.white))
                    : Icon(Icons.person, size: 60, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text("Upload a portrait photo"),
              SizedBox(height: 6),
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text(profileUploaded
                    ? "Change Profile Photo"
                    : "Upload Profile Photo"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700),
                onPressed: _pickProfileImage,
              ),
              SizedBox(height: 20),

              // Name, Email, Phone
              _buildTextField("Name", _nameController),
              _buildTextField("Email", _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField("Phone", _phoneController,
                  keyboardType: TextInputType.phone),

              // License number
              _buildTextField("Driving Licence Number", _licenseController),

              // Vehicle numbers (dynamic)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Vehicle Numbers",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._vehicleControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TextEditingController controller = entry.value;
                    return Row(
                      children: [
                        Expanded(
                            child:
                                _buildTextField("Vehicle Number ${idx + 1}", controller)),
                        if (_vehicleControllers.length > 1)
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeVehicleField(idx),
                          ),
                      ],
                    );
                  }).toList(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text("Add Vehicle"),
                      onPressed: _addVehicleField,
                    ),
                  ),
                ],
              ),

              // Aadhaar number
              _buildTextField("Aadhaar Number", _adharController,
                  keyboardType: TextInputType.number, isRequired: true),

              // ID proof
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: idProofType,
                decoration: InputDecoration(
                  labelText: "Select ID Proof Type",
                  border: OutlineInputBorder(),
                ),
                items: ["Aadhaar Card", "Driving Licence", "Passport", "Voter ID"]
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      idProofType = v;
                    });
                  }
                },
              ),
              SizedBox(height: 6),
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text(idProofUploaded
                    ? "$idProofType ✅"
                    : "$idProofType"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700),
                onPressed: _pickIDProof,
              ),

              SizedBox(height: 20),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700),
                  onPressed: _submitProfile,
                  child: Text("Submit Profile",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TextField builder
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool isRequired = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
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
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
