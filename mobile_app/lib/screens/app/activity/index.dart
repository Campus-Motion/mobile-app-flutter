import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/constants/colors.dart';

class ActivityIndexScreen extends StatelessWidget {
  const ActivityIndexScreen({super.key});

  static dynamic _navigationFunction(BuildContext context, int index){
    switch(index) {
      case 0 : 
        return Navigator.pushNamed(context, AppRoutes.dashboard);
      case 1 :
        return Navigator.pushNamed(context, AppRoutes.trail);
      case 2 :
        return Navigator.pushNamed(context, AppRoutes.social);
      case 3 : 
        return Navigator.pushNamed(context, AppRoutes.profile);
      case _ :
        return Navigator.pushNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MasterContainer(
        scrollable: false, // Critical: Allows Expanded TabBarView to work within the Column
        padding: EdgeInsets.zero,
        bottomNavigationBar: CampusMotionBottomBar(currentIndex: 1, onTap: _navigationFunction, context: context),
        children: [
          const SizedBox(height: 50), // Top safe area spacing
          
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activity',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // TabBar
          const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Connected Trail'),
            ],
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              children: [
                _buildEventsTab(),
                _buildTrailTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EVENTS
  // ==========================================
  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // My Enrolled Activities Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'My Enrolled Activities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        
        SizedBox(
          height: 120, // Height for the horizontal scroller
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildEnrolledCard('Basketball Game', 'Tomorrow, 18:00', Icons.sports_basketball, Colors.orange),
              _buildEnrolledCard('Morning Yoga', 'Friday, 07:00', Icons.self_improvement, Colors.teal),
              _buildEnrolledCard('Tennis Practice', 'Sunday, 10:00', Icons.sports_tennis, Colors.green),
            ],
          ),
        ),

        const SizedBox(height: 35),

        // Upcoming Events Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Discover Upcoming Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              _buildUpcomingEventCard(
                title: 'Campus Marathon 2026',
                date: 'May 20, 2026',
                location: 'Main Square',
                spotsLeft: 12,
              ),
              _buildUpcomingEventCard(
                title: 'Inter-faculty Volleyball',
                date: 'May 22, 2026',
                location: 'Sports Hall A',
                spotsLeft: 4,
              ),
              _buildUpcomingEventCard(
                title: 'Sunset Cycling Route',
                date: 'May 25, 2026',
                location: 'Lake Geneva',
                spotsLeft: 20,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildEnrolledCard(String title, String time, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard({required String title, required String date, required String location, required int spotsLeft}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Image Placeholder
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(child: Icon(Icons.event, color: Colors.white54, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '$spotsLeft spots left',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {}, // Future DB connection
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Join Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: CONNECTED TRAIL
  // ==========================================
  Widget _buildTrailTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 100, color: AppColors.primary),
          const SizedBox(height: 30),
          const Text(
            'Campus Motion Trail',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            'Embark on our connected campus trail. Scan QR codes at checkpoints, track your time, and compete on the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 40),
          
          // Trail Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrailStat(Icons.flag, '7', 'Checkpoints'),
              _buildTrailStat(Icons.route, '5 km', 'Distance'),
              _buildTrailStat(Icons.timer, '45m', 'Avg. Time'),
            ],
          ),
          
          const Spacer(),

          // Start Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trail starting module coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: const Text(
                'START TRAIL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrailStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
