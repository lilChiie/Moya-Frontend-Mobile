import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/dialog_utils.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rank_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/route_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedAvatar = 'assets/images/avatar/commoner.png';
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '******');
  final TextEditingController _confirmPasswordController = TextEditingController(text: '******');

  List<Map<String, dynamic>> _ranks = [];
  int _userPoints = 0;
  String _currentRankName = 'Commoner';
  int _destinationsVisited = 0;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userPoints = prefs.getInt('user_points') ?? 0;

    // Load dynamic visited destinations count from history
    final historyList = await DestinationHistoryManager().getHistory();
    _destinationsVisited = historyList.length;

    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'John Doe';
      _emailController.text = prefs.getString('user_email') ?? 'johndoe@example.com';
    });
    
    // Fetch profile from backend
    final profileService = ProfileService();
    final profileResult = await profileService.getProfile();
    if (profileResult['success'] && profileResult['data'] != null) {
      final profileData = profileResult['data'];
      _userPoints = profileData['total_points'] ?? _userPoints;
      
      setState(() {
        _nameController.text = profileData['name'] ?? _nameController.text;
        _emailController.text = profileData['email'] ?? _emailController.text;
        // Also update local cache
        prefs.setString('user_name', _nameController.text);
        prefs.setInt('user_points', _userPoints);
      });
    }

    // Fetch dynamic ranks
    final rankService = RankService();
    final result = await rankService.getRanks();
    if (result['success']) {
      final List<dynamic> data = result['data'];
      setState(() {
        _ranks = data.map((e) => e as Map<String, dynamic>).toList();
        
        Map<String, dynamic>? currentRank;
        for (var rank in _ranks) {
          final int minPoint = int.tryParse(rank['min_point'].toString()) ?? 0;
          final int maxPoint = int.tryParse(rank['max_point'].toString()) ?? 0;
          if (_userPoints >= minPoint && _userPoints <= maxPoint) {
            currentRank = rank;
            break;
          }
        }
        
        if (currentRank == null && _ranks.isNotEmpty) {
           currentRank = _ranks.firstWhere(
             (r) => r['name'].toString().toLowerCase() == 'commoner' || r['min_point'] == 0, 
             orElse: () => _ranks.last
           );
        }
        
        if (currentRank != null) {
           _currentRankName = currentRank['name']?.toString() ?? 'Commoner';
           final savedAvatar = prefs.getString('user_avatar');
           if (savedAvatar != null && savedAvatar.isNotEmpty) {
             _selectedAvatar = savedAvatar;
           } else {
             _selectedAvatar = currentRank['avatar']?.toString() ?? '';
           }
        }
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _showAvatarPicker(BuildContext context) {
    final List<Map<String, dynamic>> sortedRanks = List.from(_ranks);
    sortedRanks.sort((a, b) {
      final aMin = int.tryParse(a['min_point'].toString()) ?? 0;
      final bMin = int.tryParse(b['min_point'].toString()) ?? 0;
      return aMin.compareTo(bMin);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A2F),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: sortedRanks.length,
                  itemBuilder: (context, index) {
                    final rank = sortedRanks[index];
                    final avatar = rank['avatar']?.toString() ?? '';
                    final isSelected = _selectedAvatar == avatar;
                    final minPoint = int.tryParse(rank['min_point'].toString()) ?? 0;
                    final isLocked = minPoint > _userPoints;
                    
                    return GestureDetector(
                      onTap: isLocked ? null : () async {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_avatar', avatar);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLocked ? Colors.grey.shade200 : const Color(0xFFF2F5EA),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF7D9240) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: isLocked ? 0.3 : 1.0,
                              child: avatar.startsWith('http')
                                  ? Image.network(
                                      avatar,
                                      headers: const {'ngrok-skip-browser-warning': 'true'},
                                    )
                                  : Image.asset(
                                      avatar.isNotEmpty ? avatar : 'assets/images/avatar/commoner.png'
                                    ),
                            ),
                            if (isLocked)
                              const Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7D9240),
        onRefresh: _loadProfileData,
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7D9240),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
          children: [
            // ====================================================
            // HERO IMAGE & AVATAR
            // ====================================================
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Hero Image with bottom margin to fit avatar
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/other/hero_image.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Avatar positioned overlapping
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _showAvatarPicker(context),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2F5EA),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _selectedAvatar.startsWith('http')
                              ? Image.network(
                                  _selectedAvatar,
                                  headers: const {'ngrok-skip-browser-warning': 'true'},
                                )
                              : Image.asset(
                                  _selectedAvatar.isNotEmpty ? _selectedAvatar : 'assets/images/avatar/commoner.png'
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF7D9240),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Leaderboard Button
                Positioned(
                  right: 16,
                  top: 16,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6), // Subtle Gold tint
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.emoji_events, color: Color(0xFFB8860B), size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Leaderboard',
                            style: TextStyle(
                              color: Color(0xFFB8860B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ====================================================
            // USER INFO
            // ====================================================
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : 'John Doe',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A2F),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0DF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rank: $_currentRankName',
                    style: const TextStyle(
                      color: Color(0xFF7D9240),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0DF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Points: $_userPoints',
                    style: const TextStyle(
                      color: Color(0xFF7D9240),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/destinations',
                  arguments: {'tab': 'history'},
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: const Color(0xFF7D9240), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_destinationsVisited Destinations Visited',
                      style: const TextStyle(
                        color: Color(0xFF1E3A2F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF7D9240),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF7D9240)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ====================================================
            // FORM
            // ====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field
                  _buildTextField(
                    label: 'Username',
                    controller: _nameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  _buildTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () async {
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;
                        
                        if (password != confirmPassword) {
                          AppDialogs.showStatusDialog(
                            context: context,
                            isSuccess: false,
                            title: 'Validation Error',
                            message: 'Passwords do not match.',
                            buttonText: 'OK',
                            onPressed: () => Navigator.pop(context),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);
                        
                        final profileService = ProfileService();
                        final result = await profileService.updateProfile(
                          name: _nameController.text,
                          password: password == '******' || password.isEmpty ? null : password,
                        );
                        
                        setState(() => _isSaving = false);
                        
                        if (mounted) {
                          AppDialogs.showStatusDialog(
                            context: context,
                            isSuccess: result['success'],
                            title: result['success'] ? 'Success' : 'Error',
                            message: result['message'] ?? (result['success'] ? 'Profile updated successfully' : 'Failed to update profile'),
                            buttonText: 'OK',
                            onPressed: () => Navigator.pop(context),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7D9240),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        AppDialogs.showConfirmDialog(
                          context: context,
                          title: 'Logout',
                          message: 'Are you sure you want to log out?',
                          confirmText: 'Logout',
                          onConfirm: () async {
                            final authService = AuthService();
                            await authService.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            }
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF9FBF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF7D9240), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
