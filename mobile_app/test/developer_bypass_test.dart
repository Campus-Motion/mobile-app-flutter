import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/event_service.dart';
import 'package:mobile_app/services/news_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/models/activity.dart';

void main() {
  setUp(() {
    ApiService.mockMode = true;
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  group('Developer Bypass & MockDataService Tests', () {
    test('MockDataService handles core endpoints', () {
      final mock = MockDataService();

      final userRes = mock.handleGet('/users/me');
      expect(userRes.statusCode, 200);
      expect(userRes.body, contains('Robin.Doe'));

      final newsRes = mock.handleGet('/news');
      expect(newsRes.statusCode, 200);
      expect(newsRes.body, contains('Welcome to Campus Motion 2026!'));

      final eventsRes = mock.handleGet('/events');
      expect(eventsRes.statusCode, 200);
      expect(eventsRes.body, contains('Sunset Lake Trail Run'));

      final activitiesRes = mock.handleGet('/activities');
      expect(activitiesRes.statusCode, 200);
      expect(activitiesRes.body, contains('Morning Campus Run'));
    });

    test('AuthService.enterDemoMode initializes valid demo session', () async {
      final auth = AuthService();
      final user = await auth.enterDemoMode();

      expect(user.username, 'Robin.Doe');
      expect(user.email, 'robin.doe@epfl.ch');
      expect(auth.currentUser, isNotNull);
      expect(ApiService().isAuthenticated, isTrue);
      expect(ApiService.mockMode, isTrue);
    });

    test('Domain services function seamlessly via mock bypass', () async {
      final userService = UserService();
      final activityService = ActivityService();
      final eventService = EventService();
      final newsService = NewsService();

      // User profile
      final me = await userService.getMe();
      expect(me.username, 'Robin.Doe');

      // Preferences
      final prefs = await userService.getPreferences();
      expect(prefs.preferredSports, contains('running'));

      // News
      final news = await newsService.fetchLatestNews();
      expect(news.isNotEmpty, isTrue);

      // Events
      final events = await eventService.getEvents();
      expect(events.isNotEmpty, isTrue);

      // Activities & creation
      final initialActivities = await activityService.getActivities();
      final initialCount = initialActivities.length;

      final created = await activityService.createActivity(
        Activity(
          id: 0,
          title: 'Demo Test Run',
          type: 'run',
          userId: 1,
          isPublic: true,
          duration: 42.0,
          createdAt: DateTime.now(),
        ),
      );
      expect(created.title, 'Demo Test Run');

      final updatedActivities = await activityService.getActivities();
      expect(updatedActivities.length, initialCount + 1);
    });
  });
}
