import 'package:flutter/material.dart';

// Pages
import 'managevehicle.dart';
import 'bookingmanagement.dart';
import 'viewbookinghistory.dart';
import 'complaint.dart';
import 'viewreplay.dart';
import 'feedback.dart';
import 'profile.dart'; // ✅ Profile page
import '../user/notifications.dart'; // Notification Screen

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VehicleOwnerHomePage(),
    ),
  );
}

class VehicleOwnerHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: Text(
          "Vehicle Owner Home",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            tooltip: "My Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleOwnerProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            tooltip: "Notifications",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildCard(
                context,
                icon: Icons.directions_car,
                label: "Manage Vehicle",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleManagementPage(),
                    ),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.request_page,
                label: "Booking Requests",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingRequestsPage(),
                    ),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.history,
                label: "Booking History",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Historypage()),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.report,
                label: "Submit Complaint",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintPagevehicle(),
                    ),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.message,
                label: "Admin Replies",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReplayPage()),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.feedback,
                label: "Feedback",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewFeedbackPage()),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.notifications_active,
                label: "Notifications",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Card Widget
  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.blue.shade700),
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
