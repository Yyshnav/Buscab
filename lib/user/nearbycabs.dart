import 'package:flutter/material.dart';

class NearbyCabsUI extends StatefulWidget {
  const NearbyCabsUI({super.key});

  @override
  State<NearbyCabsUI> createState() => _NearbyCabsUIState();
}

class _NearbyCabsUIState extends State<NearbyCabsUI> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();

  // ----------- Updated Cab List with Vehicle Numbers ----------
  final List<Map<String, dynamic>> cabs = [
    {
      "name": "City Taxi",
      "distance": "0.5 km",
      "time": "2 min",
      "car": "Suzuki Alto",
      "type": "Mini",
      "vehicleNo": "KL 21 AB 9090",
    },
    {
      "name": "GoCab",
      "distance": "0.8 km",
      "time": "3 min",
      "car": "Hyundai i20",
      "type": "Sedan",
      "vehicleNo": "KL 55 CC 1122",
    },
    {
      "name": "FastRide",
      "distance": "1.1 km",
      "time": "5 min",
      "car": "Toyota Innova",
      "type": "SUV",
      "vehicleNo": "KL 08 DF 7722",
    }
  ];

  String selectedType = "All";

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // ----------- Fare Calculation Example -----------
  double calculateFare(String distance) {
    final km = double.tryParse(distance.replaceAll(" km", "")) ?? 1.0;
    return km * 25; // Example: ₹25 per km
  }

  // ----------- Bottom Sheet -----------
  void showBookingSheet(Map<String, dynamic> cab) {
    final double fare = calculateFare(cab["distance"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
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

                  // Cab Name + Car
                  Text(
                    cab["name"],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    cab["car"],
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),

                  SizedBox(height: 10),

                  // Vehicle Number
                  Row(
                    children: [
                      Icon(Icons.numbers, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Vehicle Number: ${cab["vehicleNo"]}",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Distance + arrival
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Distance: ${cab["distance"]}", style: TextStyle(fontSize: 16)),
                      Text("Arrival: ${cab["time"]}", style: TextStyle(fontSize: 16)),
                    ],
                  ),

                  SizedBox(height: 25),

                  // Date Picker
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                    ),
                    child: Text(
                      selectedDate == null
                          ? "Select Booking Date"
                          : "Date: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    ),
                  ),

                  SizedBox(height: 10),

                  // Time Picker
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                    ),
                    child: Text(
                      selectedTime == null
                          ? "Select Booking Time"
                          : "Time: ${selectedTime!.format(context)}",
                    ),
                  ),

                  SizedBox(height: 25),

                  // Fare Display
                  Text(
                    "Estimated Fare: ₹${fare.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  SizedBox(height: 25),

                  // BOOK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please select date & time")),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Cab booked successfully!"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Confirm Booking",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),
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
        : cabs.where((cab) => cab["type"] == selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Cabs"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [

          const SizedBox(height: 15),

          // Pickup & Drop Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                TextField(
                  controller: pickup,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                    hintText: "Pickup location",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: drop,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    hintText: "Drop location",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FILTER LIST
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 15),
              children: [
                filterChip("All"),
                filterChip("Mini"),
                filterChip("Sedan"),
                filterChip("SUV"),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // CAB LIST
          Expanded(
            child: ListView.builder(
              itemCount: filteredCabs.length,
              itemBuilder: (context, index) {
                final cab = filteredCabs[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      radius: 28,
                      child: Icon(Icons.local_taxi, color: Colors.blue, size: 30),
                    ),
                    title: Text(
                      cab["name"],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Text(
                      "${cab["car"]} • ${cab["distance"]} away • ${cab["time"]}",
                      style: TextStyle(fontSize: 14),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) {
          setState(() {
            selectedType = label;
          });
        },
      ),
    );
  }
}
