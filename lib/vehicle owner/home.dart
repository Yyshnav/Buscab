import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'managevehicle.dart';
import 'bookingmanagement.dart';
import 'viewbookinghistory.dart';
import 'complaint.dart';
import 'feedback.dart';
import 'profile.dart';

class VehicleOwnerHomePage extends StatelessWidget {
  const VehicleOwnerHomePage({super.key});

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
                    left: -30,
                    bottom: -30,
                    child: Icon(
                      Icons.hub_rounded,
                      size: 180,
                      color: AppTheme.primary.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              title: Text(
                "Dashboard",
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
                icon: Icons.account_circle_outlined,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleOwnerProfilePage()),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Text(
                "MENU",
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  context,
                  icon: Icons.directions_car_filled_rounded,
                  title: "My Vehicles",
                  subtitle: "Manage your fleet",
                  color: AppTheme.primary,
                  index: 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VehicleManagementPage(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.assignment_turned_in_rounded,
                  title: "Bookings",
                  subtitle: "Manage requests",
                  color: AppTheme.secondary,
                  index: 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingRequestsPage(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: "Trip History",
                  subtitle: "View past trips",
                  color: const Color(0xFFF59E0B),
                  index: 2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Historypage()),
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.insights_rounded,
                  title: "Reviews",
                  subtitle: "User feedback",
                  color: const Color(0xFF818CF8),
                  index: 3,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ViewFeedbackPage()),
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: "Support",
                  subtitle: "Contact Admin",
                  color: const Color(0xFFF43F5E),
                  index: 4,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ComplaintPagevehicle()),
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ).animate().scale(delay: (index * 100).ms),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.darkTheme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.darkTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.1),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
