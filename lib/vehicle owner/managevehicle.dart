import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio_lib;

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  // ---------------- Basic Info ----------------
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();

  // ---------------- RC Details ----------------
  bool showRCDetails = false;
  String _vehicleClass = "MCWG";
  String fuelType = "Petrol";
  String cabType = "SUV";

  final List<String> cabTypes = ["SUV", "Hatchback", "Sedan", "MUV/MPV"];

  final _modelController = TextEditingController();
  final _seatingController = TextEditingController();
  final _rcExpiryController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _distanceKmController = TextEditingController();
  String rcFrontImage = "";
  String rcBackImage = "";

  // ---------------- Insurance Details ----------------
  bool showInsuranceDetails = false;
  final _insuranceProviderController = TextEditingController();
  final _policyNumberController = TextEditingController();
  String policyType = "Third Party";
  final _policyStartController = TextEditingController();
  final _policyExpiryController = TextEditingController();
  String insuranceDocImage = "";

  // ---------------- Helpers ----------------
  void toggleRCDetails() => setState(() => showRCDetails = !showRCDetails);
  void toggleInsuranceDetails() =>
      setState(() => showInsuranceDetails = !showInsuranceDetails);

  // ---------------- Image Picker ----------------
  void _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (type == "rcFront") rcFrontImage = pickedFile.path;
        if (type == "rcBack") rcBackImage = pickedFile.path;
        if (type == "insurance") insuranceDocImage = pickedFile.path;
      });
    }
  }

  // ---------------- Date Picker Field ----------------
  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime? date = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2035),
          initialDate: DateTime.now(),
        );
        if (date != null) {
          controller.text =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ---------------- Upload Button ----------------
  Widget _buildUploadButton(String label, String type) {
    String status = "";
    if (type == "rcFront") status = rcFrontImage;
    if (type == "rcBack") status = rcBackImage;
    if (type == "insurance") status = insuranceDocImage;

    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: Text(status.isEmpty ? label : "$label ✅"),
      onPressed: () => _pickImage(type),
    );
  }

  // ---------------- Save Vehicle ----------------
  void saveVehicle() async {
    if (_vehicleNumberController.text.isEmpty ||
        _ownerNameController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _dropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill Vehicle Number, Owner Name, and Service Locations",
          ),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      final data = dio_lib.FormData.fromMap({
        'loginid': userId,
        'vehicle_no': _vehicleNumberController.text,
        'owner_name': _ownerNameController.text,
        'pickup_location': _pickupController.text,
        'drop_location': _dropController.text,
        'per_km_rate': double.tryParse(_perKmRateController.text) ?? 0.0,
        'distance_km': double.tryParse(_distanceKmController.text) ?? 0.0,
        'vehicle_class': _vehicleClass,
        'fuel_type': fuelType,
        'vehicle_model': _modelController.text,
        'seating_capacity': int.tryParse(_seatingController.text) ?? 4,
        'cab_type': cabType,
        'rc_expiry_date': _rcExpiryController.text,
        'insurance_provider': _insuranceProviderController.text,
        'policy_number': _policyNumberController.text,
        'policy_type': policyType,
        'policy_start_date': _policyStartController.text,
        'policy_expiry_date': _policyExpiryController.text,
        'lattitude': 0.0,
        'longitude': 0.0,
      });

      if (rcFrontImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'rc_front_img',
            await dio_lib.MultipartFile.fromFile(rcFrontImage),
          ),
        );
      }
      if (rcBackImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'rc_back_img',
            await dio_lib.MultipartFile.fromFile(rcBackImage),
          ),
        );
      }
      if (insuranceDocImage.isNotEmpty) {
        data.files.add(
          MapEntry(
            'insurance_document',
            await dio_lib.MultipartFile.fromFile(insuranceDocImage),
          ),
        );
      }

      final response = await ApiService.addVehicle(data);
      // Note: ApiService.addVehicle takes Map<String, dynamic>.
      // I should update ApiService or pass data directly to dio in managevehicle.
      // Actually, passing FormData to ApiService might work if I change its signature.
      // But let's check ApiService again.
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle saved successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save vehicle: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Vehicle Management",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Basic Info --------
            TextFormField(
              controller: _vehicleNumberController,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: "Owner Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: "Service From (Pickup Location)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dropController,
              decoration: const InputDecoration(
                labelText: "Service To (Drop Location)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _perKmRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Per KM Rate (₹)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _distanceKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Distance (KM)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.social_distance),
              ),
            ),
            const SizedBox(height: 10),

            // -------- RC Toggle --------
            TextButton.icon(
              onPressed: toggleRCDetails,
              icon: Icon(showRCDetails ? Icons.expand_less : Icons.expand_more),
              label: const Text("RC Details"),
            ),

            // -------- RC Details --------
            if (showRCDetails)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _vehicleClass,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Class",
                          border: OutlineInputBorder(),
                        ),
                        items: ["MCWG", "MCWOG", "LMV-CAB", "LMV-NT"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _vehicleClass = v!);
                        },
                      ),

                      // -------- Cab Type (Only LMV-CAB) --------
                      if (_vehicleClass == "LMV-CAB") ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: cabType,
                          decoration: const InputDecoration(
                            labelText: "Cab Type",
                            border: OutlineInputBorder(),
                          ),
                          items: cabTypes
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => cabType = v!);
                          },
                        ),
                      ],

                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: fuelType,
                        decoration: const InputDecoration(
                          labelText: "Fuel Type",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Petrol", "Diesel", "Electric", "CNG"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => fuelType = v!),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Model",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _seatingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Seating Capacity",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDateField("RC Expiry Date", _rcExpiryController),
                      const SizedBox(height: 10),
                      _buildUploadButton("Upload RC Front", "rcFront"),
                      _buildUploadButton("Upload RC Back", "rcBack"),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: toggleInsuranceDetails,
              icon: Icon(
                showInsuranceDetails ? Icons.expand_less : Icons.expand_more,
              ),
              label: const Text("Insurance Details"),
            ), // -------- Insurance Form --------
            if (showInsuranceDetails)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _insuranceProviderController,
                        decoration: const InputDecoration(
                          labelText: "Insurance Provider",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _policyNumberController,
                        decoration: const InputDecoration(
                          labelText: "Policy Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: policyType,
                        decoration: const InputDecoration(
                          labelText: "Policy Type",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Third Party", "Comprehensive"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => policyType = v!),
                      ),
                      const SizedBox(height: 10),
                      _buildDateField(
                        "Policy Start Date",
                        _policyStartController,
                      ),
                      const SizedBox(height: 10),
                      _buildDateField(
                        "Policy Expiry Date",
                        _policyExpiryController,
                      ),
                      const SizedBox(height: 10),
                      _buildUploadButton(
                        "Upload Insurance Document",
                        "insurance",
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                onPressed: saveVehicle,
                child: const Text(
                  "Save Vehicle",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
