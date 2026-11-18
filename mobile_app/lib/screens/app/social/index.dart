import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/widgets/user_list_tile.dart';

class SocialIndexScreen extends StatefulWidget {
  const SocialIndexScreen({super.key});

  @override
  State<SocialIndexScreen> createState() => _SocialIndexScreenState();
}

class _SocialIndexScreenState extends State<SocialIndexScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  List<User> _followers = [];
  List<User> _following = [];
  bool _isLoading = true;

  // Find people state
  static const int _minSearchLength = 2;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _searchFailed = false;

  @override
  void initState() {
    super.initState();
    _loadSocialData();
  }

  Future<void> _loadSocialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        final followers = await _userService.getFollowers(currentUserId);
        final following = await _userService.getFollowing(currentUserId);

        setState(() {
          _followers = followers;
          _following = following;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load social connections: $e')),
      );
    }
  }

  /// Waits for a pause in typing so one request is sent, not one per key.
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final query = text.trim();
    if (query.length < _minSearchLength) {
      setState(() {
        _searchQuery = query;
        _searchResults = [];
        _isSearching = false;
        _searchFailed = false;
      });
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _searchUsers(query),
    );
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
      _searchFailed = false;
    });

    try {
      final results = await _userService.searchUsers(query);
      // Ignore a response that arrives after the user changed the query.
      if (!mounted || query != _searchQuery) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || query != _searchQuery) return;
      setState(() {
        _searchFailed = true;
        _isSearching = false;
      });
    }
  }

  Future<void> _toggleFollowUser(User user, bool isFollowing) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      if (isFollowing) {
        await _userService.unfollowUser(user.id);
      } else {
        await _userService.followUser(user.id);
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing
                ? 'Unfollowed ${user.username}'
                : 'Followed ${user.username}!',
          ),
        ),
      );
      _loadSocialData(); // Refresh followers/following lists
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: MasterContainer(
        scrollable: false,
        padding: EdgeInsets.zero,
        bottomNavigationBar: const CampusMotionBottomBar(currentIndex: 2),
        onRefresh: _loadSocialData,
        children: [
          const SizedBox(height: 50),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Social Feed',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
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
              Tab(text: 'Following'),
              Tab(text: 'Followers'),
              Tab(text: 'Find people'),
            ],
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _buildUserList(_following, isFollowingTab: true),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _buildUserList(_followers, isFollowingTab: false),
                _buildSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> users, {required bool isFollowingTab}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isFollowingTab
                  ? 'You are not following anyone yet.'
                  : 'You do not have any followers yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserListTile(user: user, trailing: _buildFollowButton(user));
      },
    );
  }

  Widget _buildFollowButton(User user) {
    final isFollowing = _following.any((u) => u.id == user.id);

    return ElevatedButton(
      onPressed: () => _toggleFollowUser(user, isFollowing),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey.shade200 : AppColors.primary,
        foregroundColor: isFollowing ? Colors.black87 : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        isFollowing ? 'Unfollow' : 'Follow',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by username',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.length < _minSearchLength) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find people',
        subtitle: 'Type at least 2 letters of a username.',
      );
    }
    if (_isSearching) return const LoadingState();
    if (_searchFailed) {
      return ErrorState(
        message: 'Search is unavailable right now.',
        onRetry: () => _searchUsers(_searchQuery),
      );
    }
    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: 'No members match "$_searchQuery"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return UserListTile(user: user, trailing: _buildFollowButton(user));
      },
    );
  }
}
