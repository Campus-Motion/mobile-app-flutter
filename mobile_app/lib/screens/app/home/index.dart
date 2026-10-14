import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/widgets/event_preview_card.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/news_card.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/top_bar.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/services/news_service.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/services/event_service.dart';
import 'package:mobile_app/constants/colors.dart';

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
    _newsFuture = _newsService.fetchLatestNews();
    _eventsFuture = _eventService.getEvents(limit: 5, after : DateTime.now().toIso8601String());
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _newsService.fetchLatestNews();
      _eventsFuture = _eventService.getEvents(limit: 5);
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

  Widget _buildUpcomingEventsSlider() {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: EventPreviewCard.size,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        } else if (snapshot.hasError) {
          return const SizedBox(
            height: EventPreviewCard.size,
            child: Center(child: Text('Failed to load events', style: TextStyle(color: AppColors.error))),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: EventPreviewCard.size,
            child: Center(child: Text('No upcoming events', style: TextStyle(color: AppColors.textMuted))),
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
            itemBuilder: (context, index) => EventPreviewCard(event: events[index]),
          ),
        );
      },
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
            children : [
              const SectionHeader(title: 'Latest News'),
              const SizedBox(height: 24),
              FutureBuilder<List<NewsItem>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load news',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Retry',
                              onPressed: _refreshNews,
                              width: 140,
                              height: 44,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No news available.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  final newsItems = snapshot.data!;
                  return Column(
                    children: newsItems.map((item) => NewsCard(item: item)).toList(),
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
