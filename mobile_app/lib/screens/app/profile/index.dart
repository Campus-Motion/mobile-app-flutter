import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/constants/colors.dart';

class ProfileIndexScreen extends StatelessWidget {
  const ProfileIndexScreen({super.key});

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

  void _shareProfile() {
    Share.share('Check out my Campus Motion profile! Join me and track your campus activities.');
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      bottomNavigationBar: CampusMotionBottomBar(currentIndex: 3, onTap: _navigationFunction, context: context),
      children : [
        // Top Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children : [
            OutlinedButton.icon(
              onPressed : () => Navigator.pushNamed(context, AppRoutes.editProfile),
              icon : const Icon(Icons.edit, size: 16, color: AppColors.primary),
              label: const Text('Edit', style: TextStyle(color:AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side : const BorderSide(width: 1, color : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )
            ),
            const Image(height : 40, image: AssetImage('assets/images/logo_peach.png')),
            Row(
              children : [
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed : _shareProfile,
                  color: AppColors.primary
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.parameters),
                  color : AppColors.primary
                )
              ]
            )
          ]
        ),
        const SizedBox(height: 30),
        
        // Profile Header
        Column(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/splash-icon.png'),
              radius: 45
            ),
            const SizedBox(height: 15),
            const Text(
              'Forrest Gump',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 5),
            const Text(
              'EPFL Student • Greenbow, AL',
              style: TextStyle(color: Colors.grey, fontSize: 14)
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "Mom always said: Life is like a box of chocolates...",
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 40),

        // Stats Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Activities', '142'),
            _buildStatCard('Distance', '1,204 km'),
            _buildStatCard('Active Time', '45h 20m'),
          ],
        ),

        const SizedBox(height: 40),

        // Recent Activities
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Recent Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        
        _buildActivityCard(
          icon: Icons.directions_run,
          title: 'Morning Run across the US',
          date: 'Today at 6:00 AM',
          distance: '25.4 km',
          duration: '2h 15m',
        ),
        _buildActivityCard(
          icon: Icons.directions_walk,
          title: 'Campus Walk',
          date: 'Yesterday',
          distance: '4.2 km',
          duration: '45m',
        ),
        _buildActivityCard(
          icon: Icons.pedal_bike,
          title: 'Lake Geneva Cycling',
          date: 'May 10, 2026',
          distance: '45.0 km',
          duration: '1h 50m',
        ),
      ]
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActivityCard({required IconData icon, required String title, required String date, required String distance, required String duration}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
