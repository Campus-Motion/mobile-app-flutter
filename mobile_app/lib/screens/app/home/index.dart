import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/widgets/event_preview_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/news_card.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/top_bar.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/services/news_service.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/services/event_service.dart';

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

  Future<List<Event>> _loadUpcomingEvents() {
    return _eventService.getEvents(
      limit: 5,
      after: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _newsFuture = _loadNews();
      _eventsFuture = _loadEvents();
    });
    await Future.wait([_newsFuture, _eventsFuture]);
  }

  static dynamic _navigationFunction(BuildContext context, int index) {
    switch (index) {
      case 0:
        return Navigator.pushNamed(context, AppRoutes.dashboard);
      case 1:
        return Navigator.pushNamed(context, AppRoutes.trail);
      case 2:
        return Navigator.pushNamed(context, AppRoutes.social);
      case 3:
        return Navigator.pushNamed(context, AppRoutes.profile);
      case _:
        return Navigator.pushNamed(context, AppRoutes.dashboard);
    }
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

        return SizedBox(
          height: EventPreviewCard.size,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventPreviewCard(
                event: event,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.eventDetails,
                    arguments: event.id,
                  );
                  if (!mounted) return;
                  setState(() {
                    _eventsFuture = _loadUpcomingEvents();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      padding: EdgeInsets.zero,
      onRefresh: _refreshDashboard,
      bottomNavigationBar: CampusMotionBottomBar(
        currentIndex: 0,
        onTap: _navigationFunction,
        context: context,
      ),
      children: [
        const TopAppBar(),
        const SizedBox(height: 20),

        // Upcoming Events Section
        const SectionHeader(
          title: 'Upcoming Events',
          padding: EdgeInsets.symmetric(horizontal: 24.0),
        ),
        const SizedBox(height: 16),
        _buildUpcomingEventsSlider(),
        const SizedBox(height: 32),

        // Latest News Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Latest News'),
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
                    children: newsItems
                        .map((item) => NewsCard(item: item))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
