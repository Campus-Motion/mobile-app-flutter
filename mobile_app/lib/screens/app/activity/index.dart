import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/services/event_service.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/models/user.dart';

class ActivityIndexScreen extends StatefulWidget {
  const ActivityIndexScreen({super.key});

  @override
  State<ActivityIndexScreen> createState() => _ActivityIndexScreenState();
}

class _ActivityIndexScreenState extends State<ActivityIndexScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final ActivityService _activityService = ActivityService();
  final AuthService _authService = AuthService();

  late TabController _tabController;

  List<Activity> _myActivities = [];
  List<Event> _enrolledEvents = [];
  List<Event> _discoverEvents = [];
  
  bool _isLoadingActivities = true;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Refresh state to show/hide FAB depending on active tab
      setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadActivities(),
      _loadEventsData(),
    ]);
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final activities = await _activityService.getActivities(limit: 50);
      setState(() {
        _myActivities = activities;
        _isLoadingActivities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingActivities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activities: $e')),
      );
    }
  }

  Future<void> _loadEventsData() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final currentUserId = _authService.currentUser?.id;
      final currentUsername = _authService.currentUser?.username;
      final currentDate = DateTime.now().subtract(Duration(hours:1)).toIso8601String();
      final events = await _eventService.getEvents(limit: 30, after:currentDate);

      final isEnrolledFlags = await Future.wait(events.map((event) async {
        try {
          final List<User> participants = await _eventService.getParticipants(event.id);
          return participants.any((p) {
            if (p.id != 0 && currentUserId != null && p.id == currentUserId) {
              return true;
            }
            if (currentUsername != null && p.username.isNotEmpty) {
              return p.username.toLowerCase() == currentUsername.toLowerCase();
            }
            return false;
          });
        } catch (e) {
          debugPrint('Failed to load participants for event ${event.id}: $e');
          return false;
        }
      }));

      List<Event> enrolled = [];
      List<Event> discover = [];

      for (int i = 0; i < events.length; i++) {
        if (isEnrolledFlags[i]) {
          enrolled.add(events[i]);
        } else {
          discover.add(events[i]);
        }
      }

      setState(() {
        _enrolledEvents = enrolled;
        _discoverEvents = discover;
        _isLoadingEvents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    }
  }

  Future<void> _joinEvent(int eventId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _eventService.joinEvent(eventId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
        _loadEventsData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join event: $e')),
        );
      }
    }
  }

  Future<void> _leaveEvent(int eventId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _eventService.leaveEvent(eventId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the event.')),
        );
        _loadEventsData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave event: $e')),
        );
      }
    }
  }

  Future<void> _deleteActivity(int activityId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _activityService.deleteActivity(activityId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted.')),
        );
        _loadActivities();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete activity: $e')),
        );
      }
    }
  }

  void _showLogActivityDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    
    // Choose default title based on time
    final hour = DateTime.now().hour;
    String timeOfDay = 'Workout';
    if (hour < 12) {
      timeOfDay = 'Morning';
    } else if (hour < 17) {
      timeOfDay = 'Afternoon';
    } else {
      timeOfDay = 'Evening';
    }
    
    String selectedType = 'run';
    titleController.text = '$timeOfDay Run';

    final durationController = TextEditingController();
    bool isPublic = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log Activity',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title Field
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Activity Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Activity Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'run', child: Text('Run')),
                        DropdownMenuItem(value: 'walk', child: Text('Walk')),
                        DropdownMenuItem(value: 'cycle', child: Text('Cycle')),
                        DropdownMenuItem(value: 'hike', child: Text('Hike')),
                        DropdownMenuItem(value: 'swim', child: Text('Swim')),
                        DropdownMenuItem(value: 'climbing', child: Text('Climbing')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedType = val;
                            // Dynamically update default title
                            final capitalizedType = val[0].toUpperCase() + val.substring(1);
                            titleController.text = '$timeOfDay $capitalizedType';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration Input
                    TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter duration';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Public Toggle
                    SwitchListTile(
                      title: const Text('Make Activity Public'),
                      subtitle: const Text('Visible to other campus users in their social feeds'),
                      value: isPublic,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() {
                          isPublic = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(modalContext); // Close bottom sheet
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );

                            try {
                              final activity = Activity(
                                id: 0,
                                title: titleController.text,
                                type: selectedType,
                                userId: _authService.currentUser?.id ?? 0,
                                isPublic: isPublic,
                                createdAt: DateTime.now(),
                                duration: double.parse(durationController.text),
                              );
                              await _activityService.createActivity(activity);
                              
                              if (!mounted) return;
                              Navigator.pop(context); // Dismiss loading spinner
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Activity logged successfully!')),
                              );
                              _loadActivities();
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(context); // Dismiss loading spinner
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to log activity: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      case 'walk':
        return Icons.directions_walk;
      case 'cycle':
        return Icons.pedal_bike;
      case 'hike':
        return Icons.terrain;
      case 'swim':
        return Icons.pool;
      case 'climbing':
        return Icons.filter_hdr;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'run': return Colors.deepOrange;
      case 'walk': return Colors.teal;
      case 'cycle': return Colors.blue;
      case 'hike': return Colors.green;
      case 'swim': return Colors.cyan;
      default: return AppColors.primary;
    }
  }

  String _getActivityDurationString(double? minutes) {
    if (minutes == null) return '--';
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).round();
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  String _getActivityDistanceString(double? minutes, String type) {
    if (minutes == null) return '--';
    double speedKmh = 5.0;
    switch (type.toLowerCase()) {
      case 'run': speedKmh = 10.0; break;
      case 'walk': speedKmh = 5.0; break;
      case 'cycle': speedKmh = 20.0; break;
      case 'hike': speedKmh = 4.0; break;
      case 'swim': speedKmh = 2.0; break;
    }
    final distance = speedKmh * (minutes / 60.0);
    return '${distance.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: MasterContainer(
        scrollable: false,
        padding: EdgeInsets.zero,
        bottomNavigationBar: CampusMotionBottomBar(currentIndex: 1, onTap: _navigationFunction, context: context),
        onRefresh: _loadAllData,
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: _showLogActivityDialog,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        children: [
          const SizedBox(height: 50),
          
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activity Hub',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // TabBar (3 Tabs)
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Activities'),
              Tab(text: 'Events'),
              Tab(text: 'Connected Trail'),
            ],
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingActivities
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildActivitiesTab(),
                _isLoadingEvents
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildEventsTab(),
                _buildTrailTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MY PERSONAL ACTIVITIES FEED
  // ==========================================
  Widget _buildActivitiesTab() {
    if (_myActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_run_outlined, size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No activities tracked yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record or log your physical workouts using the floating action button below!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      itemCount: _myActivities.length,
      itemBuilder: (context, index) {
        final activity = _myActivities[index];
        final formattedDate = DateFormat('MMMM d, yyyy - HH:mm').format(activity.createdAt);
        final color = _getActivityColor(activity.type);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Activity'),
                  content: Text('Are you sure you want to delete "${activity.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteActivity(activity.id);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getActivityIcon(activity.type), color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              activity.isPublic ? Icons.public : Icons.lock_outline,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (activity.body != null && activity.body!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            activity.body!,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getActivityDistanceString(activity.duration, activity.type),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getActivityDurationString(activity.duration),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: EVENTS (GROUP ACTIVITIES)
  // ==========================================
  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // My Enrolled Activities Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'My Enrolled Group Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        
        if (_enrolledEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Text(
              'You haven\'t joined any group events yet. Join some below!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          SizedBox(
            height: 140, // Height for the horizontal scroller
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _enrolledEvents.length,
              itemBuilder: (context, index) {
                final event = _enrolledEvents[index];
                final formattedTime = DateFormat('MMM d, HH:mm').format(event.startTime);
                return _buildEnrolledCard(
                  event.id,
                  event.title,
                  formattedTime,
                  _getEventIcon(event.title),
                  _getEventColor(event.title),
                );
              },
            ),
          ),

        const SizedBox(height: 35),

        // Upcoming Events Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Discover Upcoming Group Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),

        if (_discoverEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Center(
              child: Text(
                'No new upcoming events available.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: _discoverEvents.map((event) {
                final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(event.startTime);
                final location = event.distanceM != null 
                    ? 'Distance: ${(event.distanceM! / 1000).toStringAsFixed(1)} km'
                    : 'Campus Trail';
                return _buildUpcomingEventCard(
                  id: event.id,
                  title: event.title,
                  date: formattedDate,
                  location: location,
                  spotsLeft: event.participantCount,
                );
              }).toList(),
            ),
          )
      ],
    );
  }

  Widget _buildEnrolledCard(int id, String title, String time, IconData icon, Color color) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Event'),
            content: Text('Are you sure you want to leave "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _leaveEvent(id);
                },
                child: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 18),
                  onPressed: () => _leaveEvent(id),
                ),
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard({required int id, required String title, required String date, required String location, required int spotsLeft}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      '$spotsLeft joined',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
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
                    onPressed: () => _joinEvent(id),
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

  IconData _getEventIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('basketball')) return Icons.sports_basketball;
    if (t.contains('yoga') || t.contains('meditation')) return Icons.self_improvement;
    if (t.contains('tennis')) return Icons.sports_tennis;
    if (t.contains('run') || t.contains('marathon') || t.contains('jog')) return Icons.directions_run;
    if (t.contains('cycle') || t.contains('bike') || t.contains('cycling')) return Icons.pedal_bike;
    if (t.contains('volleyball')) return Icons.sports_volleyball;
    if (t.contains('soccer') || t.contains('football')) return Icons.sports_soccer;
    return Icons.sports_score;
  }

  Color _getEventColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('basketball')) return Colors.orange;
    if (t.contains('yoga')) return Colors.teal;
    if (t.contains('tennis')) return Colors.green;
    if (t.contains('run')) return Colors.deepOrange;
    if (t.contains('cycle')) return Colors.blue;
    if (t.contains('volleyball')) return Colors.purple;
    return AppColors.primary;
  }

  // ==========================================
  // TAB 3: CONNECTED TRAIL
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrailStat(Icons.flag, '7', 'Checkpoints'),
              _buildTrailStat(Icons.route, '5 km', 'Distance'),
              _buildTrailStat(Icons.timer, '45m', 'Avg. Time'),
            ],
          ),
          
          const Spacer(),

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
