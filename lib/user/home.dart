import 'package:flutter/material.dart';

// Import your pages
import 'liftservices.dart';        // LiftServiceHome
import 'nearbycabs.dart';          // NearbyCabsUI
import 'sendcomplaint.dart';       // ComplaintPage
import 'replay.dart';              // ViewReplyPage
import 'viewfeedback.dart';        // FeedbackPage
import 'profile.dart';             // UserProfilePage
import 'busdetails.dart';          // BusDetailsPage (to be created)

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserHomePage(),
    ),
  );
}

class UserHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Blue background
        title: Text(
          "User Home",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,       // White title
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white), // White icons
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            tooltip: "Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(),
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
                icon: Icons.motorcycle,
                label: "Lift Service",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LiftServiceHome()),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.local_taxi,
                label: "Nearby Cabs",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NearbyCabsUI()),
                  );
                },
              ),
              _buildCard(
                context,
                icon: Icons.directions_bus,
                label: "Bus Details",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BusDetailsPage()),
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
                    MaterialPageRoute(builder: (_) => ComplaintPage()),
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
                    MaterialPageRoute(builder: (_) => ViewReplyPage()),
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
                    MaterialPageRoute(builder: (_) => FeedbackPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              Icon(icon, size: 50, color: Colors.blue), // Card icon in blue
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue, // Card text in blue
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
