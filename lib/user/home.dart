import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'liftservices.dart';
import 'nearbycabs.dart';
import 'sendcomplaint.dart';
import 'viewfeedback.dart';
import 'profile.dart';
import 'bookinghistory.dart';
import 'notifications.dart';
import 'package:ridesync/vehicle owner/managevehicle.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.darkGradient,
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -20,
                    child: Icon(
                      Icons.blur_on_rounded,
                      size: 200,
                      color: AppTheme.primary.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              title: Text(
                "Home",
                style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
            ),
            actions: [
              _buildAppBarAction(
                icon: Icons.notifications_none_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
              _buildAppBarAction(
                icon: Icons.account_circle_outlined,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfilePage()),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _buildServiceCard(
                  context,
                  icon: Icons.electric_bolt_rounded,
                  label: "Lifts",
                  subtitle: "Share a Ride",
                  color: AppTheme.secondary,
                  index: 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiftServiceHome()),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.local_taxi_rounded,
                  label: "Cabs",
                  subtitle: "Book a Cab",
                  color: AppTheme.primary,
                  index: 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyCabsUI()),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.history_edu_rounded,
                  label: "Booking History",
                  subtitle: "View your trips",
                  color: const Color(0xFF818CF8),
                  index: 2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingHistoryPage(),
                    ),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.forum_outlined,
                  label: "Feedback",
                  subtitle: "Your Feedback",
                  color: const Color(0xFFD946EF),
                  index: 3,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FeedbackPage()),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.shield_outlined,
                  label: "Support",
                  subtitle: "Contact Support",
                  color: const Color(0xFFF43F5E),
                  index: 4,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComplaintPage()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: color),
            ).animate().scale(delay: (index * 100).ms, duration: 400.ms),
            const SizedBox(height: 20),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }
}
