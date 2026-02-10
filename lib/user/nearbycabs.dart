import 'package:flutter/material.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class NearbyCabsUI extends StatefulWidget {
  const NearbyCabsUI({super.key});

  @override
  State<NearbyCabsUI> createState() => _NearbyCabsUIState();
}

class _NearbyCabsUIState extends State<NearbyCabsUI> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();

  List<dynamic> cabs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCabs();
  }

  void _fetchCabs() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.getVehicles(
        pickup: pickup.text.isEmpty ? null : pickup.text,
        drop: drop.text.isEmpty ? null : drop.text,
        cabType: selectedType == "All" ? null : selectedType,
      );
      if (response.statusCode == 200) {
        setState(() {
          cabs = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch cabs: $e")));
    }
  }

  String selectedType = "All";

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // ----------- ETA Calculation -----------
  String calculateETA(String? distance) {
    if (distance == null) return "N/A";
    final double dist =
        double.tryParse(distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (dist == 0.0) return "N/A";

    // speed = 30km/h => 0.5km/min
    final int minutes = (dist / 0.5).round();
    return "$minutes mins";
  }

  // ----------- Fare Calculation -----------
  double calculateFare(Map<String, dynamic> cab) {
    final double rate =
        double.tryParse(cab["per_km_rate"]?.toString() ?? "0") ?? 0.0;
    final double dist =
        double.tryParse(cab["distance_km"]?.toString() ?? "0") ?? 0.0;
    if (rate > 0 && dist > 0) {
      return rate * dist;
    }

    // Fallback to distance string if per_km_rate is missing
    final String? distanceStr = cab["distance"];
    if (distanceStr == null) return 50.0;
    final km = double.tryParse(distanceStr.replaceAll(" km", "")) ?? 1.0;
    return km * 25;
  }

  // ----------- Call Owner -----------
  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialer")),
        );
      }
    }
  }

  // ----------- Bottom Sheet -----------
  void showBookingSheet(Map<String, dynamic> cab) {
    final double fare = calculateFare(cab);
    final String eta = calculateETA(cab["distance"]);
    int requestedSeats = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,

                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (cab["vehicle_image"] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "http://192.168.1.5:5000${cab["vehicle_image"]}",
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Cab Name + Car
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cab["owner_name"] ?? "Taxi Service",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${cab["vehicle_class"]} - ${cab["vehicle_model"]}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cab["mobile_number"] != null)
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          child: IconButton(
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPressed: () =>
                                _makeCall(cab["mobile_number"].toString()),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Detail Grid
                  Row(
                    children: [
                      Expanded(
                        child: detailTile(
                          Icons.local_gas_station,
                          "Fuel",
                          cab["fuel_type"] ?? "N/A",
                        ),
                      ),
                      Expanded(
                        child: detailTile(
                          Icons.airline_seat_recline_normal,
                          "Seats",
                          "${cab["seating_capacity"] ?? 4}",
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: detailTile(
                          Icons.category,
                          "Type",
                          cab["cab_type"] ?? "N/A",
                        ),
                      ),
                      Expanded(
                        child: detailTile(
                          Icons.numbers,
                          "Plate",
                          cab["vehicle_no"] ?? "N/A",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Distance + arrival
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Distance: ${cab["distance"] ?? 'N/A'}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Arrival: ${cab["time"] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              "Est. Arrival: $eta",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 30),

                  // Owner Contact Info
                  if (cab["mobile_number"] != null) ...[
                    const Text(
                      "Owner Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(cab["owner_name"] ?? "Owner"),
                      subtitle: Text("Contact: ${cab["mobile_number"]}"),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _makeCall(cab["mobile_number"].toString()),
                      ),
                    ),
                    const Divider(height: 30),
                  ],

                  // Fare Calculation
                  if (cab["per_km_rate"] != null &&
                      cab["distance_km"] != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fare Calculation",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Distance: ${cab["distance_km"]} km"),
                              Text("Rate: ₹${cab["per_km_rate"]}/km"),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹${(double.tryParse(cab["per_km_rate"].toString()) ?? 0) * (double.tryParse(cab["distance_km"].toString()) ?? 0)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 30),

                  // Date Picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    label: Text(
                      selectedDate == null
                          ? "Select Booking Date"
                          : "Date: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Time Picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    label: Text(
                      selectedTime == null
                          ? "Select Booking Time"
                          : "Time: ${selectedTime!.format(context)}",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seat Counter
                  const Text(
                    "Select Seats",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          if (requestedSeats > 1) {
                            setModalState(() => requestedSeats--);
                          }
                        },
                      ),
                      Text(
                        "$requestedSeats",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          final maxSeats =
                              int.tryParse(
                                cab["seating_capacity"]?.toString() ?? "4",
                              ) ??
                              4;
                          if (requestedSeats < maxSeats) {
                            setModalState(() => requestedSeats++);
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        "Max: ${cab["seating_capacity"] ?? 4}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Fare Display
                  Text(
                    "Total Amount: ₹${(fare * requestedSeats).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // BOOK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select date & time"),
                            ),
                          );
                          return;
                        }

                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final loginId = prefs.getInt('login_id');

                          if (loginId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Error: Login ID missing. Please login again.",
                                ),
                              ),
                            );
                            return;
                          }

                          final data = {
                            'login_id': loginId,
                            'status': 'Pending',
                            'vehicle_no': int.parse(
                              cab["id"].toString(),
                            ), // Ensure int PK
                            'date':
                                "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                            'time':
                                "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                            'total_amount': double.parse(
                              (fare * requestedSeats).toString(),
                            ),
                            'requested_seats': requestedSeats,
                          };

                          final response = await ApiService.bookVehicle(data);
                          if (response.statusCode == 201) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Booking request sent successfully!",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Booking failed: ${response.data}",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          String errorMsg = "Failed to book cab: $e";
                          if (e is DioException && e.response != null) {
                            errorMsg = "Booking failed: ${e.response?.data}";
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(errorMsg)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Booking",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------- UI LIST & FILTERS ------------------------

  @override
  Widget build(BuildContext context) {
    final filteredCabs = selectedType == "All"
        ? cabs
        : cabs.where((cab) => cab["cab_type"] == selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Cabs"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // -------- Search Bar --------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pickup,
                    decoration: InputDecoration(
                      hintText: "Pickup Location",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: drop,
                    decoration: InputDecoration(
                      hintText: "Drop Location",
                      prefixIcon: const Icon(Icons.flag, color: Colors.red),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _fetchCabs,
                  icon: const Icon(Icons.search, color: Colors.blue),
                ),
              ],
            ),
          ),

          // -------- Filter Options --------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ["All", "SUV", "Hatchback", "Sedan", "MUV/MPV"].map((
                type,
              ) {
                final bool isSelected = selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => selectedType = type);
                        _fetchCabs();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 15),

          // CAB LIST
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : cabs.isEmpty
              ? const Expanded(child: Center(child: Text("No Cabs Found")))
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredCabs.length,
                    itemBuilder: (context, index) {
                      final cab = filteredCabs[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 28,
                            child: const Icon(
                              Icons.local_taxi,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            cab["owner_name"] ?? "Taxi",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Text(
                            "${cab["vehicle_model"]} • ${cab["vehicle_no"]}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => showBookingSheet(cab),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget filterChip(String label) {
    bool selected = selectedType == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey.shade300,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) {
          setState(() {
            selectedType = label;
          });
        },
      ),
    );
  }

  Widget detailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
