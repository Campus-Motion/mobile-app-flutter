import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
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

  // Search User State
  final TextEditingController _searchIdController = TextEditingController();
  User? _searchedUser;
  bool _isSearching = false;
  String? _searchError;

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

  Future<void> _searchUser() async {
    final idText = _searchIdController.text.trim();
    if (idText.isEmpty) return;

    final id = int.tryParse(idText);
    if (id == null) {
      setState(() {
        _searchError = 'Please enter a valid numeric ID';
        _searchedUser = null;
      });
      return;
    }

    if (id == _authService.currentUser?.id) {
      setState(() {
        _searchError = 'You cannot search or follow yourself';
        _searchedUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchedUser = null;
    });

    try {
      final user = await _userService.getUser(id);
      setState(() {
        _searchedUser = user;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'User with ID $id not found';
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
      // Refresh searched user to update follow state
      if (_searchedUser != null && _searchedUser!.id == user.id) {
        _searchUser();
      }
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
    _searchIdController.dispose();
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
              Tab(text: 'Find User'),
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

  Future<void> _openUserProfile(User user) async {
    await Navigator.pushNamed(context, AppRoutes.userProfilePath(user.id));
    if (!mounted) return;
    _loadSocialData();
  }

  Widget _buildFollowButton(User user, bool isFollowing) {
    return ElevatedButton(
      onPressed: () => _toggleFollowUser(user, isFollowing),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing
            ? AppColors.surfaceLight
            : AppColors.primary,
        foregroundColor: isFollowing
            ? AppColors.textPrimary
            : AppColors.background,
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
        final isFollowing = _following.any((u) => u.id == user.id);

        return UserListTile(
          user: user,
          onTap: () => _openUserProfile(user),
          trailing: _buildFollowButton(user, isFollowing),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    final isFollowingSearched =
        _searchedUser != null &&
        _following.any((u) => u.id == _searchedUser!.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find User by ID',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter User ID (e.g. 2)',
                    filled: true,
                    fillColor: Colors.grey.shade100,
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
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            Text(
              _searchError!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 30),
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_searchedUser != null)
            UserListTile(
              user: _searchedUser!,
              onTap: () => _openUserProfile(_searchedUser!),
              trailing: _buildFollowButton(_searchedUser!, isFollowingSearched),
            ),
        ],
      ),
    );
  }
}
