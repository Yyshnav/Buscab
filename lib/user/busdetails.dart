import 'package:flutter/material.dart';

// Dummy Map Screen to show current bus location
class BusMapScreen extends StatelessWidget {
  final String busLocation;

  const BusMapScreen({super.key, required this.busLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bus Location"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          "Bus is currently at: $busLocation",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class BusDetailsPage extends StatefulWidget {
  const BusDetailsPage({super.key});

  @override
  State<BusDetailsPage> createState() => _BusDetailsPageState();
}

class _BusDetailsPageState extends State<BusDetailsPage> {
  TextEditingController pickup = TextEditingController();
  TextEditingController drop = TextEditingController();

  // Selected Bus Type for filter
  String selectedBusType = "All";

  // Sample bus data
  final List<Map<String, String>> buses = [
    {
      "name": "KSRTC Express",
      "type": "AC",
      "pickup": "Kochi",
      "drop": "Thrissur",
      "currentLocation": "Angamaly"
    },
    {
      "name": "Fast Travels",
      "type": "Non-AC",
      "pickup": "Kochi",
      "drop": "Aluva",
      "currentLocation": "Aluva"
    },
    {
      "name": "Metro Bus",
      "type": "AC",
      "pickup": "Kakkanad",
      "drop": "Ernakulam",
      "currentLocation": "Edappally"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filtered buses based on type
    final filteredBuses = selectedBusType == "All"
        ? buses
        : buses.where((bus) => bus["type"] == selectedBusType).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bus Details", style: TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 15),
          // Pickup & Drop Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                TextField(
                  controller: pickup,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                    hintText: "Pickup Location",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: drop,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    hintText: "Drop Location",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 15),

          // Bus Type Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: DropdownButtonFormField<String>(
              value: selectedBusType,
              decoration: InputDecoration(
                labelText: "Select Bus Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              items: ["All", "AC", "Non-AC"].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedBusType = val!;
                });
              },
            ),
          ),

          SizedBox(height: 15),

          // Bus List
          Expanded(
            child: ListView.builder(
              itemCount: filteredBuses.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                    title: Text(
                      bus["name"]!,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Text(
                      "${bus["pickup"]} → ${bus["drop"]} • ${bus["type"]}",
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.location_on, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusMapScreen(
                              busLocation: bus["currentLocation"]!,
                            ),
                          ),
                        );
                      },
                      color: Colors.white,
                    ),
                    tileColor: Colors.blue.shade700,
                    textColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
