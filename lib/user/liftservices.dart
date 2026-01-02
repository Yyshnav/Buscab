import 'package:flutter/material.dart';

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

  // Dummy Data
  final List<Map<String, dynamic>> lifts = [
    {
      "driver": "Arjun Kumar",
      "vehicle": "Hyundai i20 - KL 21 AA 9900",
      "pickup": "Kochi",
      "drop": "Thrissur",
      "currentLocation": "Kakkanad",
      "time": "10:30 AM",
      "seats": 2,
      "fare": 150,
      "completed": false,
      "rated": false,
      "rating": 0.0,
      "feedback": "",
    },
    {
      "driver": "Nikhil Menon",
      "vehicle": "Royal Enfield - KL 16 BB 1122",
      "pickup": "Kakkanad",
      "drop": "Aluva",
      "currentLocation": "Aluva",
      "time": "9:00 AM",
      "seats": 1,
      "fare": 60,
      "completed": false,
      "rated": false,
      "rating": 0.0,
      "feedback": "",
    },
  ];

  final List<Map<String, dynamic>> requests = [
    {"name": "Nikhil Menon", "seats": 1, "pickup": "Kakkanad", "drop": "Aluva"},
    {"name": "Sneha Raj", "seats": 2, "pickup": "Kalamassery", "drop": "Edappally"},
  ];

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      // ----------------- 0: Available Lifts & Provide Lift -----------------
      SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Available Lifts", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...lifts.map((lift) => Card(
                  child: ListTile(
                    title: Text(lift["driver"]),
                    subtitle: Text("${lift["pickup"]} → ${lift["drop"]} | Seats: ${lift["seats"]} | Fare: ₹${lift["fare"]}"),
                    trailing: ElevatedButton(
                      child: Text("Request"),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lift request sent")));
                      },
                    ),
                  ),
                )),
            SizedBox(height: 20),
            Divider(),
            Text("Provide a Lift", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ProvideLiftForm(),
          ],
        ),
      ),

      // ----------------- 1: Lift Requests / Tracking -----------------
      SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lift Requests", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...requests.map((req) => Card(
                  child: ListTile(
                    title: Text(req["name"]),
                    subtitle: Text("${req["pickup"]} → ${req["drop"]} | Seats: ${req["seats"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${req["name"]} accepted")));
                            }),
                        IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${req["name"]} rejected")));
                            }),
                      ],
                    ),
                  ),
                )),
            SizedBox(height: 20),
            Text("Lift Tracking", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...lifts.map((lift) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Driver: ${lift["driver"]}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Vehicle: ${lift["vehicle"]}"),
                        Text("Pickup: ${lift["pickup"]} → Drop: ${lift["drop"]}"),
                        if (lift["completed"] && lift["rated"]) ...[
                          SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < lift["rating"] ? Icons.star : Icons.star_border,
                                color: Colors.orange,
                                size: 20,
                              );
                            }),
                          ),
                          if ((lift["feedback"] ?? "").isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("Feedback: ${lift["feedback"]}", style: TextStyle(fontStyle: FontStyle.italic)),
                            ),
                        ],
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Calling ${lift["driver"]}...")));
                              },
                              icon: Icon(Icons.call),
                              label: Text("Call"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MapScreen(driverLocation: lift["currentLocation"]),
                                  ),
                                );
                              },
                              icon: Icon(Icons.map),
                              label: Text("View Location"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (!lift["completed"])
                          ElevatedButton(
                            onPressed: () {
                              // Step 1: Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Complete Ride"),
                                    content: Text("Are you sure you want to complete this ride?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Cancel
                                        },
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Close confirmation

                                          // Step 2: Mark ride as completed
                                          setState(() {
                                            lift["completed"] = true;
                                          });

                                          // Step 3: Show rating + feedback dialog
                                          double tempRating = 0;
                                          TextEditingController feedbackController = TextEditingController();

                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return StatefulBuilder(
                                                builder: (context, setDialogState) {
                                                  return AlertDialog(
                                                    title: Text("Rate ${lift["driver"]}"),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: List.generate(5, (index) {
                                                            return IconButton(
                                                              icon: Icon(
                                                                index < tempRating
                                                                    ? Icons.star
                                                                    : Icons.star_border,
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
                                                            hintText: "write a feedback",
                                                            border: OutlineInputBorder(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            lift["rating"] = tempRating;
                                                            lift["feedback"] =
                                                                feedbackController.text;
                                                            lift["rated"] = true;
                                                          });
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  "Rated ${lift["driver"]} $tempRating stars${feedbackController.text.isNotEmpty ? " with feedback" : ""}"),
                                                            ),
                                                          );
                                                        },
                                                        child: Text("Submit"),
                                                      )
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                        child: Text("Confirm"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text("Complete Ride"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),

      // ----------------- 2: Drivers Tab -----------------
      SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Drivers", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...lifts.map((lift) => Card(
                  child: ListTile(
                    leading: Icon(Icons.person, size: 40, color: Colors.blue),
                    title: Text(lift["driver"]),
                    subtitle: Text("${lift["vehicle"]} | ${lift["pickup"]} → ${lift["drop"]}"),
                  ),
                )),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (val) => setState(() => _currentIndex = val),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: "Lifts"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Drivers"),
        ],
      ),
    );
  }
}

// ----------------- Provide Lift Form -----------------
class ProvideLiftForm extends StatefulWidget {
  const ProvideLiftForm({super.key});

  @override
  State<ProvideLiftForm> createState() => _ProvideLiftFormState();
}

class _ProvideLiftFormState extends State<ProvideLiftForm> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();
  TextEditingController vehicle = TextEditingController();
  TextEditingController seats = TextEditingController();
  TextEditingController fare = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: pickup, decoration: inputStyle("Pickup Location", Icons.my_location)),
        SizedBox(height: 8),
        TextField(controller: drop, decoration: inputStyle("Drop Location", Icons.location_on)),
        SizedBox(height: 8),
        TextField(controller: vehicle, decoration: inputStyle("Vehicle Details", Icons.directions_car)),
        SizedBox(height: 8),
        TextField(controller: seats, keyboardType: TextInputType.number, decoration: inputStyle("Seats Available", Icons.event_seat)),
        SizedBox(height: 8),
        TextField(controller: fare, keyboardType: TextInputType.number, decoration: inputStyle("Fare per Seat", Icons.currency_rupee)),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue, minimumSize: Size(double.infinity, 50)),
          child: Text(selectedDate == null ? "Select Date" : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}"),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final result = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (result != null) setState(() => selectedTime = result);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue, minimumSize: Size(double.infinity, 50)),
          child: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lift Published Successfully")));
            },
            child: Text("Publish Lift"),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.blue),
          ),
        )
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
}
