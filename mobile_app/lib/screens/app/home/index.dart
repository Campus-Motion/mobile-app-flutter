import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/top_bar.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/services/news_service.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/services/event_service.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:intl/intl.dart';

class HomeIndexScreen extends StatefulWidget {
  const HomeIndexScreen({super.key});

  @override
  State<HomeIndexScreen> createState() => _HomeIndexScreenState();
}

class _HomeIndexScreenState extends State<HomeIndexScreen> {
  final NewsService _newsService = NewsService();
  final EventService _eventService = EventService();
  
  late Future<List<NewsItem>> _newsFuture;
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _loadNews();
    _eventsFuture = _loadEvents();
  }

  Future<List<NewsItem>> _loadNews() => _newsService.fetchLatestNews();

  Future<List<Event>> _loadEvents() => _eventService.getEvents(
      limit: 5,
      after: DateTime.now().toIso8601String(),
    );

  void _retryEvents() {
    setState(() {
      _eventsFuture = _loadEvents();
    });
  }
 
  void _retryNews() {
    setState(() {
      _newsFuture = _loadNews();
    });
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _loadNews();
      _eventsFuture = _loadEvents();
    });
    await Future.wait([_newsFuture, _eventsFuture]);
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

  Widget _buildNewsCard(NewsItem item) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.fullPhotoUrl != null)
            Image.network(
              item.fullPhotoUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(item.publishedAt),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSlider() {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(height: 140);
        } else if (snapshot.hasError) {
          return ErrorState(
            message: 'Failed to load events',
            onRetry: _retryEvents,
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const EmptyState(
            title: 'No upcoming events',
            icon: Icons.event_busy_outlined,
          );
        }

        final events = snapshot.data!;
        final dateFormat = DateFormat('MMM d, HH:mm');

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(
                event.title, 
                dateFormat.format(event.startTime), 
                Icons.event, 
                Colors.teal
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(String title, String date, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(date, style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      padding: EdgeInsets.zero,
      onRefresh: _refreshNews,
      bottomNavigationBar: CampusMotionBottomBar(currentIndex: 0, onTap: _navigationFunction, context: context),
      children : [
        const TopAppBar(),
        const SizedBox(height: 20),
        
        // Upcoming Events Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildUpcomingEventsSlider(),
        const SizedBox(height: 32),

        // Latest News Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children : [
              const Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<NewsItem>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingState(height: 160);
                  } else if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Failed to load news',
                      onRetry: _retryNews,
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const EmptyState(
                      title: 'No news available',
                      icon: Icons.newspaper_outlined,
                    );
                  }

                  final newsItems = snapshot.data!;
                  return Column(
                    children: newsItems.map((item) => _buildNewsCard(item)).toList(),
                  );
                },
              ),
            ]
          )
        ),
      ]
    );
  }
}
