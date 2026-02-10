import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio;

void main() {
  runApp(MaterialApp(home: LiftServiceHome()));
}

// Dummy Map Screen for demonstration
class MapScreen extends StatelessWidget {
  final String driverLocation; // Replace with LatLng if using coordinates
  const MapScreen({super.key, required this.driverLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Location")),
      body: Center(
        child: Text(
          "Driver is at: $driverLocation",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class LiftServiceHome extends StatefulWidget {
  const LiftServiceHome({super.key});

  @override
  State<LiftServiceHome> createState() => _LiftServiceHomeState();
}

class _LiftServiceHomeState extends State<LiftServiceHome> {
  int _currentIndex = 0;
  List<dynamic> lifts = [];
  List<dynamic> myOfferedLifts = [];
  bool isLoading = true;
  bool isMyLiftsLoading = true;
  List<dynamic> incomingRequests = [];
  List<dynamic> myRequests = [];
  bool isRequestsLoading = true;
  int? currentLoginId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    _fetchLifts();
    _fetchMyOfferedLifts();
    _fetchRequests();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLoginId = prefs.getInt('login_id');
    });
    print('DEBUG: Current login ID loaded: $currentLoginId');
  }

  Future<void> _fetchLifts() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      final response = await ApiService.getLifts(excludeUserId: loginId);
      if (response.statusCode == 200) {
        setState(() {
          lifts = response.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch lifts: $e")));
    }
  }

  Future<void> _fetchMyOfferedLifts() async {
    setState(() => isMyLiftsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      if (loginId != null) {
        final response = await ApiService.getLifts(userId: loginId);
        if (response.statusCode == 200) {
          setState(() {
            myOfferedLifts = response.data ?? [];
            isMyLiftsLoading = false;
          });
        }
      } else {
        setState(() => isMyLiftsLoading = false);
      }
    } catch (e) {
      setState(() => isMyLiftsLoading = false);
      print("Error fetching my lifts: $e");
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => isRequestsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');

      if (loginId != null) {
        // 1. Fetch requests MADE BY ME
        final myReqRes = await ApiService.getMyLiftRequests(loginId);
        if (myReqRes.statusCode == 200) {
          setState(() {
            myRequests = myReqRes.data;
          });
        }

        // 2. Fetch requests FOR MY LIFTS
        // We use myOfferedLifts which was already fetched
        List<dynamic> allIncoming = [];
        for (var lift in myOfferedLifts) {
          final incRes = await ApiService.getIncomingLiftRequests(lift['id']);
          if (incRes.statusCode == 200) {
            allIncoming.addAll(incRes.data);
          }
        }
        setState(() {
          incomingRequests = allIncoming;
        });
      }
      setState(() => isRequestsLoading = false);
    } catch (e) {
      setState(() => isRequestsLoading = false);
      print("Error fetching requests: $e");
    }
  }

  Future<void> _sendRequest(int liftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginId = prefs.getInt('login_id');
      if (loginId == null) return;

      final response = await ApiService.requestLift({
        'lift_id': liftId,
        'user_id': loginId,
        'requested_seats': 1, // Default to 1 for now
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lift request sent successfully")),
        );
        _fetchRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send request: $e")));
    }
  }

  Future<void> _updateRequestStatus(int requestId, String status) async {
    try {
      final response = await ApiService.updateLiftRequestStatus(
        requestId,
        status,
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Request $status")));
        _fetchRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      // 0: Available Lifts
      RefreshIndicator(
        onRefresh: _fetchLifts,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Available Lifts",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (lifts.isEmpty)
                Text("No lifts available")
              else
                ...lifts.map(
                  (lift) => Card(
                    child: ListTile(
                      title: Text(lift["pickup_location"] ?? "Unknown"),
                      subtitle: Text(
                        "${lift["pickup_location"]} → ${lift["drop_location"]} | Seats: ${lift["seats"]} | Time: ${lift["time"]}",
                      ),
                      trailing: ElevatedButton(
                        child: Text("Request"),
                        onPressed: () => _sendRequest(lift['id']),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // 1: My Lifts (Manage incoming requests)
      RefreshIndicator(
        onRefresh: () async {
          _fetchMyOfferedLifts();
          _fetchRequests();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Offered Lifts",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (isMyLiftsLoading)
                Center(child: CircularProgressIndicator())
              else if (myOfferedLifts.isEmpty)
                Text("You haven't offered any lifts yet")
              else
                ...myOfferedLifts.map((lift) {
                  // Find requests for THIS specific lift
                  final liftRequests = incomingRequests
                      .where((r) => r['lift_id']?['id'] == lift['id'])
                      .toList();

                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${lift["pickup_location"]} → ${lift["drop_location"]}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              _buildInfoChip(
                                Icons.event_seat,
                                "${lift["seats"]} seats",
                              ),
                            ],
                          ),
                          Divider(),
                          Text(
                            "Requests for this lift:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (liftRequests.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text("No requests yet"),
                            )
                          else
                            ...liftRequests.map(
                              (req) => ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  req["user_id"]?["username"] ?? "Unknown",
                                ),
                                subtitle: Text(
                                  "Seats: ${req["requested_seats"]} | Status: ${req["status"]}",
                                ),
                                trailing: req["status"] == 'Pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed: () =>
                                                _updateRequestStatus(
                                                  req['id'],
                                                  'Accepted',
                                                ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _updateRequestStatus(
                                                  req['id'],
                                                  'Rejected',
                                                ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        req["status"],
                                        style: TextStyle(
                                          color: req["status"] == 'Accepted'
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),

      // 2: My Sent Requests (Tracking)
      RefreshIndicator(
        onRefresh: _fetchRequests,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Sent Requests",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (isRequestsLoading)
                const Center(child: CircularProgressIndicator())
              else if (myRequests.isEmpty)
                const Text("You haven't requested any lifts yet")
              else
                ...myRequests.map((req) {
                  final lift = req["lift_id"] is Map ? req["lift_id"] : null;
                  // Use user_details if available (provided by our updated serializer)
                  // otherwise fallback to login_id for basic info
                  final driver = (lift?["user_details"] is Map)
                      ? lift!["user_details"]
                      : (lift?["login_id"] is Map ? lift!["login_id"] : null);
                  final vehicle = lift?["vehicle_no"] is Map
                      ? lift!["vehicle_no"]
                      : null;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver?["name"] ?? "Driver",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (driver?["mobile_number"] != null)
                                      Text(
                                        "📞 ${driver!["mobile_number"]}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: req["status"] == 'Accepted'
                                      ? Colors.green.shade100
                                      : req["status"] == 'Rejected'
                                      ? Colors.red.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  req["status"] ?? "Pending",
                                  style: TextStyle(
                                    color: req["status"] == 'Accepted'
                                        ? Colors.green.shade700
                                        : req["status"] == 'Rejected'
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lift?["pickup_location"] ?? "Unknown",
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lift?["drop_location"] ?? "Unknown",
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (vehicle?["vehicle_no"] != null)
                                _buildInfoChip(
                                  Icons.directions_car,
                                  vehicle!["vehicle_no"].toString(),
                                ),
                              if (lift?["date"] != null)
                                _buildInfoChip(
                                  Icons.calendar_today,
                                  lift["date"],
                                ),
                              if (lift?["time"] != null)
                                _buildInfoChip(Icons.access_time, lift["time"]),
                              _buildInfoChip(
                                Icons.event_seat,
                                "${req["requested_seats"]} seat(s)",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),

      // 3: Provide Lift (The Form)
      SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Offer a Lift",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ProvideLiftForm(
              onSuccess: () {
                _fetchMyOfferedLifts();
                setState(() => _currentIndex = 1); // Switch to My Lifts
              },
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Available"),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "My Lifts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "My Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "Offer Lift",
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(dynamic lift) {
    double tempRating = 0;
    TextEditingController feedbackController = TextEditingController();
    TextEditingController reportController = TextEditingController();
    bool isReported = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Rate Driver"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 30,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            tempRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write feedback...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isReported,
                        onChanged: (val) {
                          setDialogState(() {
                            isReported = val ?? false;
                          });
                        },
                      ),
                      const Text("Report this driver?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (isReported)
                    TextField(
                      controller: reportController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: "Why are you reporting this driver?",
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final loginId = prefs.getInt('login_id');

                      await ApiService.submitRating({
                        'login_id': loginId,
                        'vehicle_no': lift['vehicle_no'],
                        'rating': tempRating,
                      });

                      if (feedbackController.text.isNotEmpty) {
                        await ApiService.submitFeedback({
                          'login_id': loginId,
                          'feedback': feedbackController.text,
                        });
                      }

                      if (isReported && reportController.text.isNotEmpty) {
                        await ApiService.submitComplaint({
                          'login_id': loginId,
                          'reported_login_id':
                              lift['login_id'], // Map lift provider ID
                          'complaint': reportController.text,
                          'complaint_type': 'Provider Report',
                        });
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isReported
                                ? "Reported and Rated successfully!"
                                : "Rated successfully!",
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to submit: $e")),
                      );
                    }
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// ----------------- Provide Lift Form -----------------
class ProvideLiftForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const ProvideLiftForm({super.key, required this.onSuccess});

  @override
  State<ProvideLiftForm> createState() => _ProvideLiftFormState();
}

class _ProvideLiftFormState extends State<ProvideLiftForm> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();
  TextEditingController vehicleNo = TextEditingController();
  TextEditingController seats = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? licenseImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        licenseImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: pickup,
          decoration: inputStyle("Pickup Location", Icons.my_location),
        ),
        SizedBox(height: 8),
        TextField(
          controller: drop,
          decoration: inputStyle("Drop Location", Icons.location_on),
        ),
        SizedBox(height: 8),
        TextField(
          controller: vehicleNo,
          decoration: inputStyle(
            "Vehicle Number (e.g. KL-01-AB-1234)",
            Icons.directions_car,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: seats,
          keyboardType: TextInputType.number,
          decoration: inputStyle("Seats Available", Icons.event_seat),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final result = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              initialDate: DateTime.now(),
            );
            if (result != null) setState(() => selectedDate = result);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(
            selectedDate == null
                ? "Select Date"
                : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final result = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (result != null) setState(() => selectedTime = result);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(
            selectedTime == null
                ? "Select Time"
                : selectedTime!.format(context),
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: licenseImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge, size: 50, color: Colors.blue),
                      Text(
                        "Upload Driving License (Mandatory)",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(licenseImage!, fit: BoxFit.cover),
                  ),
          ),
        ),
        if (licenseImage != null)
          TextButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.edit),
            label: Text("Change Image"),
          ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (selectedDate == null ||
                  selectedTime == null ||
                  vehicleNo.text.isEmpty ||
                  licenseImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please fill all details and upload driving license",
                    ),
                  ),
                );
                return;
              }

              try {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getInt('login_id');

                final String dateStr =
                    "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                final String timeStr =
                    "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

                dio.FormData formData = dio.FormData.fromMap({
                  'login_id': userId.toString(),
                  'vehicle_no': vehicleNo.text,
                  'pickup_location': pickup.text,
                  'drop_location': drop.text,
                  'seats': (int.tryParse(seats.text) ?? 1).toString(),
                  'date': dateStr,
                  'time': timeStr,
                });

                if (licenseImage != null) {
                  formData.files.add(
                    MapEntry(
                      'driving_licence',
                      await dio.MultipartFile.fromFile(
                        licenseImage!.path,
                        filename: 'license.jpg',
                      ),
                    ),
                  );
                }

                final response = await ApiService.offerLift(formData);
                if (response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lift Published Successfully")),
                  );
                  widget.onSuccess();
                  pickup.clear();
                  drop.clear();
                  vehicleNo.clear();
                  seats.clear();
                  setState(() {
                    selectedDate = null;
                    selectedTime = null;
                    licenseImage = null;
                  });
                }
              } catch (e) {
                String errorMsg = "Failed to publish lift: $e";
                if (e is dio.DioException && e.response != null) {
                  errorMsg = "Publish failed: ${e.response?.data}";
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(errorMsg)));
              }
            },
            child: Text("Publish Lift"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration inputStyle(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blue),
      filled: true,
      fillColor: Colors.grey.shade200,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
