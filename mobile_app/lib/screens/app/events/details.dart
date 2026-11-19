import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/event_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/route_map.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/stat_item.dart';
import 'package:mobile_app/widgets/user_list_tile.dart';

class EventDetailsScreen extends StatefulWidget {
  final int? eventId;
  final TileProvider? tileProvider;
  final Future<XFile?> Function()? pickFitFile;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.tileProvider,
    this.pickFitFile,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  Event? _event;
  List<User> _participants = [];
  List<Waypoint> _eventWaypoints = [];
  User? _currentUser;
  int _participantCount = 0;
  bool _isJoined = false;
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isImportingTrack = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    if (widget.eventId == null || widget.eventId! <= 0) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid or missing event ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _eventService.getEvent(widget.eventId!),
        _eventService.getParticipants(widget.eventId!),
        _eventService.getEventWaypoints(widget.eventId!),
      ]);

      final event = futures[0] as Event;
      final participants = futures[1] as List<User>;
      final waypoints = futures[2] as List<Waypoint>;

      User? currentUser = _authService.currentUser;
      if (currentUser == null) {
        try {
          currentUser = await _userService.getMe();
        } catch (_) {}
      }

      final current = currentUser;
      final isJoined =
          current != null &&
          participants.any(
            (p) =>
                p.id == current.id ||
                (current.username.isNotEmpty &&
                    p.username.toLowerCase() == current.username.toLowerCase()),
          );

      if (!mounted) return;

      setState(() {
        _event = event;
        _participants = List<User>.from(participants);
        _eventWaypoints = waypoints;
        _currentUser = currentUser;
        _participantCount = event.participantCount > participants.length
            ? event.participantCount
            : participants.length;
        _isJoined = isJoined;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _importEventTrack() async {
    if (_event == null) return;

    try {
      final picker = widget.pickFitFile ?? _eventService.pickFitFile;
      final file = await picker();
      if (file == null) {
        return;
      }

      setState(() => _isImportingTrack = true);

      final waypoints = await _eventService.importEventFitFile(
        _event!.id,
        file,
      );

      if (!mounted) return;
      setState(() {
        _eventWaypoints = waypoints;
        _isImportingTrack = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS route added and shared with participants!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImportingTrack = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing route: $e')));
    }
  }

  Future<void> _toggleJoinLeave() async {
    if (_event == null) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      if (_isJoined) {
        await _eventService.leaveEvent(_event!.id);
        if (!mounted) return;

        setState(() {
          _isJoined = false;
          if (_currentUser != null) {
            _participants.removeWhere(
              (p) =>
                  p.id == _currentUser!.id ||
                  p.username.toLowerCase() ==
                      _currentUser!.username.toLowerCase(),
            );
          }
          if (_participantCount > 0) {
            _participantCount--;
          }
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the event.')),
        );
      } else {
        await _eventService.joinEvent(_event!.id);
        if (!mounted) return;

        setState(() {
          _isJoined = true;
          if (_currentUser != null &&
              !_participants.any((p) => p.id == _currentUser!.id)) {
            _participants.add(_currentUser!);
          }
          _participantCount++;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDateTime(DateTime start, DateTime end) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final dateStr = dateFormat.format(start);
    final startTimeStr = timeFormat.format(start);
    final endTimeStr = timeFormat.format(end);

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '$dateStr • $startTimeStr – $endTimeStr';
    }

    final endFormat = DateFormat('MMM d, HH:mm');
    return '$dateStr $startTimeStr – ${endFormat.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventId == null || widget.eventId! <= 0) {
      return MasterContainer(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 60),
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Invalid or missing event ID.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(text: 'Go Back', onPressed: () => Navigator.pop(context)),
        ],
      );
    }

    if (_isLoading) {
      return MasterContainer(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 120),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      );
    }

    if (_hasError || _event == null) {
      return MasterContainer(
        onRefresh: _loadEventDetails,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 60),
          const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Failed to load event details.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(text: 'Retry', onPressed: _loadEventDetails),
          const SizedBox(height: 12),
          AppButton(
            text: 'Go Back',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }

    final event = _event!;
    final durationMinutes = event.endTime.difference(event.startTime).inMinutes;
    final isPastEvent = DateTime.now().isAfter(event.endTime);
    final isOrganizer =
        _currentUser != null &&
        (event.userId == null ||
            event.userId == _currentUser!.id ||
            _currentUser!.role == 'admin' ||
            _currentUser!.role == 'moderator');

    return MasterContainer(
      onRefresh: _loadEventDetails,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            const SizedBox(width: 4),
            const Text(
              'Event Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main Overview Card
        AppCard(
          margin: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDateTime(event.startTime, event.endTime),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatItem(label: 'Participants', value: '$_participantCount'),
                  if (event.distanceM != null)
                    StatItem(
                      label: 'Distance',
                      value: (event.distanceM! / 1000).toStringAsFixed(1),
                      unit: 'km',
                    ),
                  if (durationMinutes > 0)
                    StatItem(
                      label: 'Duration',
                      value: '$durationMinutes',
                      unit: 'min',
                    ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons: If past event and organizer without track, allow importing track.
        // Otherwise, if upcoming, allow joining/leaving.
        if (isPastEvent) ...[
          if (isOrganizer && _eventWaypoints.isEmpty) ...[
            AppButton(
              text: 'Add GPS route (.fit)',
              isLoading: _isImportingTrack,
              onPressed: _importEventTrack,
            ),
            const SizedBox(height: 20),
          ],
        ] else ...[
          AppButton(
            text: _isJoined ? 'Leave Event' : 'Join Event',
            variant: _isJoined
                ? AppButtonVariant.outline
                : AppButtonVariant.primary,
            isLoading: _isActionLoading,
            onPressed: _toggleJoinLeave,
          ),
          const SizedBox(height: 28),
        ],

        // GPS Route Map (conditioned to presence of GPS points)
        if (_eventWaypoints.isNotEmpty) ...[
          const SectionHeader(
            title: 'GPS Route',
            padding: EdgeInsets.only(bottom: 12),
          ),
          RouteMap(
            waypoints: _eventWaypoints,
            height: 260,
            tileProvider: widget.tileProvider,
          ),
          const SizedBox(height: 24),
        ],

        // Description Section
        const SectionHeader(title: 'About the Event'),
        const SizedBox(height: 12),
        AppCard(
          margin: const EdgeInsets.only(bottom: 24.0),
          child: Text(
            event.body.isNotEmpty ? event.body : 'No description provided.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // Participants Section
        SectionHeader(title: 'Participants ($_participantCount)'),
        const SizedBox(height: 12),
        if (_participants.isEmpty)
          const AppCard(
            margin: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No participants yet. Be the first to join!',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),
          )
        else
          ..._participants.map((user) => UserListTile(user: user)),
        const SizedBox(height: 24),
      ],
    );
  }
}
