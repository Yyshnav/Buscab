import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridesync/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';

// Real Map Screen to show current bus location
class BusMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String busName;
  final String arrivalTime;

  const BusMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.busName,
    required this.arrivalTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Tracking: $busName"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ridesync',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                          size: 40,
                        ),
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      busName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Expected Arrival: $arrivalTime",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  // Controller for report dialog
  TextEditingController reportController = TextEditingController();

  void showReportDialog(String busName) {
    reportController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report a Problem"),
          content: TextField(
            controller: reportController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Describe the problem...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String report = reportController.text.trim();
                if (report.isNotEmpty) {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final loginId = prefs.getInt('login_id') ?? 1;
                    await ApiService.submitComplaint({
                      'complaint': "Bus: $busName - $report",
                      'login_id': loginId,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Report submitted for $busName")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to submit report: $e")),
                    );
                  }
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Bus Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pickup & Drop Fields + Bus Type Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  TextField(
                    controller: pickup,
                    onChanged: (val) =>
                        setState(() {}), // Added real-time filter
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                      ),
                      hintText: "Pickup Location",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: drop,
                    onChanged: (val) =>
                        setState(() {}), // Added real-time filter
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      hintText: "Drop Location",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
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
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedBusType = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Bus List
            Expanded(
              child: FutureBuilder(
                future: ApiService.getAllBuses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.data == null) {
                    return const Center(child: Text("No buses available"));
                  }

                  final List<dynamic> allBuses = snapshot.data!.data;
                  final filteredBuses = allBuses.where((bus) {
                    final bool matchesType =
                        selectedBusType == "All" ||
                        bus["bus_type"] == selectedBusType;

                    final String source = (bus["source"] ?? "")
                        .toString()
                        .toLowerCase();
                    final String dest = (bus["destination"] ?? "")
                        .toString()
                        .toLowerCase();
                    final String p = pickup.text.toLowerCase();
                    final String d = drop.text.toLowerCase();

                    final bool matchesSearch =
                        (p.isEmpty || source.contains(p)) &&
                        (d.isEmpty || dest.contains(d));

                    return matchesType && matchesSearch;
                  }).toList();

                  if (filteredBuses.isEmpty) {
                    return const Center(child: Text("No buses found"));
                  }

                  return ListView.builder(
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = filteredBuses[index];

                      String status = bus["status"] ?? "On Route";
                      Color statusColor =
                          status == "Available" || status == "On Route"
                          ? Colors.green
                          : Colors.red;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const Icon(
                                Icons.directions_bus,
                                color: Colors.blue,
                                size: 40,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bus["bus_name"] ?? "Unnamed Bus",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    bus["bus_no"] ?? "",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "${bus["source"]} → ${bus["destination"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Arr: ${bus["arrival"]} | Dep: ${bus["departure"]}",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Type: ${bus["bus_type"] ?? "N/A"} | Status: $status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                // Changed Row to Wrap to prevent overflow
                                alignment: WrapAlignment.spaceAround,
                                spacing: 4,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => showReportDialog(
                                      bus["bus_name"] ?? "Unknown",
                                    ),
                                    icon: const Icon(
                                      Icons.report_problem,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      "Report",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final loginId =
                                            prefs.getInt('login_id') ?? 1;
                                        await ApiService.submitComplaint({
                                          'complaint':
                                              "Late Bus Report for ${bus["bus_name"]} (${bus["bus_no"]})",
                                          'login_id': loginId,
                                          'complaint_type': 'Late Bus',
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Late report submitted",
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Failed to submit: $e",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      "Late",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final double lat =
                                          double.tryParse(
                                            bus["latitude"]?.toString() ?? "0",
                                          ) ??
                                          0;
                                      final double lon =
                                          double.tryParse(
                                            bus["longitude"]?.toString() ?? "0",
                                          ) ??
                                          0;

                                      if (lat != 0 && lon != 0) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BusMapScreen(
                                              latitude: lat,
                                              longitude: lon,
                                              busName: bus["bus_name"] ?? "Bus",
                                              arrivalTime: bus["arrival"] ?? "",
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Track info not available",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.map_outlined,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      "Track",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
