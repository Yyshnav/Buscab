import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VehicleManagementPage(),
  ));
}

class VehicleManagementPage extends StatefulWidget {
  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final _formKey = GlobalKey<FormState>();

  // ---------------- Basic Info ----------------
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();

  // ---------------- RC Details ----------------
  bool showRCDetails = false;
  String _vehicleClass = "MCWG";
  String fuelType = "Petrol";
  final _modelController = TextEditingController();
  final _seatingController = TextEditingController();
  final _rcExpiryController = TextEditingController();
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

  // ---------------- Helper Methods ----------------
  void toggleRCDetails() {
    setState(() {
      showRCDetails = !showRCDetails;
    });
  }

  void toggleInsuranceDetails() {
    setState(() {
      showInsuranceDetails = !showInsuranceDetails;
    });
  }

  void _pickImage(String type) {
    setState(() {
      if (type == "rcFront") rcFrontImage = "Image selected";
      if (type == "rcBack") rcBackImage = "Image selected";
      if (type == "insurance") insuranceDocImage = "Image selected";
    });
  }

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
          controller.text = "${date.day}-${date.month}-${date.year}";
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildUploadButton(String label, String type) {
    String status = "";
    if (type == "rcFront") status = rcFrontImage;
    if (type == "rcBack") status = rcBackImage;
    if (type == "insurance") status = insuranceDocImage;

    return OutlinedButton.icon(
      icon: Icon(Icons.upload_file),
      label: Text(status.isEmpty ? label : "$label ✅"),
      onPressed: () => _pickImage(type),
    );
  }

  void saveVehicle() {
    if (_vehicleNumberController.text.isEmpty || _ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill Vehicle Number and Owner Name")),
      );
      return;
    }

    if (showRCDetails) {
      if (_modelController.text.isEmpty ||
          _seatingController.text.isEmpty ||
          _rcExpiryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all RC details")),
        );
        return;
      }
    }

    if (showInsuranceDetails) {
      if (_insuranceProviderController.text.isEmpty ||
          _policyNumberController.text.isEmpty ||
          _policyStartController.text.isEmpty ||
          _policyExpiryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all Insurance details")),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Vehicle saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Vehicle Management",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Basic Info --------
            TextFormField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _ownerNameController,
              decoration: InputDecoration(
                labelText: "Owner Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // -------- RC Details Toggle --------
            TextButton.icon(
              onPressed: toggleRCDetails,
              icon: Icon(showRCDetails ? Icons.expand_less : Icons.expand_more),
              label: Text("RC Details"),
            ),

            // -------- RC Details Form --------
            if (showRCDetails)
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _vehicleClass,
                        decoration: InputDecoration(
                          labelText: "Vehicle Class",
                          border: OutlineInputBorder(),
                        ),
                        items: ["MCWG", "MCWOG", "LMV", "LMV-CAB", "LMV-NT", "LMV-TR"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _vehicleClass = v!;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: fuelType,
                        decoration: InputDecoration(
                          labelText: "Fuel Type",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Petrol", "Diesel", "Electric", "CNG"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => fuelType = v!),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: "Vehicle Model",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _seatingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Seating Capacity",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildDateField("RC Expiry Date", _rcExpiryController),
                      SizedBox(height: 10),
                      _buildUploadButton("Upload RC Front", "rcFront"),
                      SizedBox(height: 5),
                      _buildUploadButton("Upload RC Back", "rcBack"),
                    ],
                  ),
                ),
              ),

            // -------- Insurance Details Toggle --------
            TextButton.icon(
              onPressed: toggleInsuranceDetails,
              icon: Icon(showInsuranceDetails ? Icons.expand_less : Icons.expand_more),
              label: Text("Insurance Details"),
            ),

            // -------- Insurance Form --------
            if (showInsuranceDetails)
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _insuranceProviderController,
                        decoration: InputDecoration(
                          labelText: "Insurance Provider",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _policyNumberController,
                        decoration: InputDecoration(
                          labelText: "Policy Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: policyType,
                        decoration: InputDecoration(
                          labelText: "Policy Type",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Third Party", "Comprehensive"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => policyType = v!),
                      ),
                      SizedBox(height: 10),
                      _buildDateField("Policy Start Date", _policyStartController),
                      SizedBox(height: 10),
                      _buildDateField("Policy Expiry Date", _policyExpiryController),
                      SizedBox(height: 10),
                      _buildUploadButton("Upload Insurance Document", "insurance"),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                child: Text("Save Vehicle", style: TextStyle(color: Colors.white)),
                onPressed: saveVehicle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
