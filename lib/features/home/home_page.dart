import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../core/services/destination_service.dart';
import '../../core/services/tourism_service.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _currentPosition;
  bool _isLoadingDestinations = true;
  bool _isLoadingCategories = true;

  String _userName = 'New User';

  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _categories = [];

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _getIconForCategory(String title) {
    title = title.toLowerCase();

    if (title.contains('nature') ||
        title.contains('gunung') ||
        title.contains('pantai')) {
      return Icons.park;
    }

    if (title.contains('culture') || title.contains('history')) {
      return Icons.theater_comedy;
    }

    if (title.contains('shop') || title.contains('mall')) {
      return Icons.shopping_bag;
    }

    if (title.contains('food') ||
        title.contains('culinary') ||
        title.contains('restaurant')) {
      return Icons.restaurant;
    }

    if (title.contains('hotel') ||
        title.contains('villa') ||
        title.contains('resort')) {
      return Icons.hotel;
    }

    if (title.contains('religion') || title.contains('mosque')) {
      return Icons.mosque;
    }

    return Icons.attractions;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _fetchDestinations();
    _fetchCategories();
    _checkLocationPermission();
  }

  // ============================================================
  // USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'New User';
      });
    }
  }

  // ============================================================
  // FETCH CATEGORIES
  // ============================================================

  Future<void> _fetchCategories() async {
    final tourismService = TourismService();
    final result = await tourismService.getTourismCategories();

    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final List<dynamic> data = result['data'];

          _categories = data.map((e) {
            final String title = e['name'] ?? e['title'] ?? 'Unknown';

            return {
              'id': e['id'],
              'title': title,
              'icon': _getIconForCategory(title),
            };
          }).toList();
        }

        _isLoadingCategories = false;
      });
    }
  }

  // ============================================================
  // FETCH DESTINATIONS
  // ============================================================

  Future<void> _fetchDestinations() async {
    final destinationService = DestinationService();
    final result = await destinationService.getDestinations();

    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final List<dynamic> data = List.from(result['data']);
          
          // Sort by ID descending to get the "latest" recommendations
          data.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

          _destinations = data.map((e) {
            final double lat =
                double.tryParse(e['latitude'].toString()) ?? 0.0;

            final double lng =
                double.tryParse(e['longitude'].toString()) ?? 0.0;

            return {
              'id': e['id'],
              'title': e['name'] ?? 'Unknown',
              'city': 'Indonesia',
              'image': e['image_url'] != null
                  ? e['image_url']
                      .toString()
                      .replaceFirst('http://', 'https://')
                  : null,
              'lat': lat,
              'lng': lng,
              'distance': null,
              'rating': 4.5,
              'isHighlyAccessible': true,
              'description': e['description'],
              'entrance_fee': e['entrance_fee'],
              'estimated_duration': e['estimated_duration'],
              'opening_time': e['opening_time'],
              'closing_time': e['closing_time'],
              'accessibility_id': e['accessibility_id'],
            };
          }).toList();
        }

        _isLoadingDestinations = false;
      });

      _calculateDistances();
    }
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        _calculateDistances();
      }
    } catch (e) {
      // Ignore location fetch errors
    }
  }

  // ============================================================
  // CALCULATE DISTANCES
  // ============================================================

  void _calculateDistances() {
    if (_currentPosition == null) return;

    setState(() {
      for (var dest in _destinations) {
        if (dest['lat'] != 0.0 && dest['lng'] != 0.0) {
          final double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            dest['lat'],
            dest['lng'],
          );

          dest['distance'] = distanceInMeters / 1000;
        }
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: RefreshIndicator(
        color: const Color(0xFF7D9240),
        onRefresh: () async {
          setState(() {
            _isLoadingDestinations = true;
            _isLoadingCategories = true;
            // location loading doesn't block UI
          });
          _checkLocationPermission(); // fire and forget
          await Future.wait([
            _loadUserData(),
            _fetchDestinations(),
            _fetchCategories(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // ====================================================
            // 1. HERO SECTION
            // ====================================================

            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/other/hero_image.png',
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // TOP BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [

                              // NOTIFICATION
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/notification',
                                  );
                                },
                                child: Stack(
                                  children: [

                                    Container(
                                      padding:
                                          const EdgeInsets.all(8),
                                      decoration:
                                          const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        size: 24,
                                        color: Colors.black87,
                                      ),
                                    ),

                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // AVATAR
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfilePage(),
                                    ),
                                  );
                                },
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundImage: AssetImage(
                                    'assets/images/avatar/commoner.png',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // GREETING
                      Text(
                        'Hi, $_userName 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A2F),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Ready to explore today?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A6B38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ====================================================
            // CONTENT STATES
            // ====================================================

            if (_isLoadingDestinations || _isLoadingCategories)

              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 80,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7D9240),
                  ),
                ),
              )
            else ...[
              // ====================================================
              // 2. DESTINATION RECOMMENDATIONS
              // ====================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Destination Recommendations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.destinations,
                        );
                      },
                      child: const Text(
                        'See all >',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5B7D46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_destinations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 40,
                  ),
                  child: Center(
                    child: Text('No destinations found'),
                  ),
                )
              else

              // ==================================================
              // DESTINATION HORIZONTAL LIST
              // ==================================================

              SizedBox(
                height: 282,

                child: ListView.builder(
                  scrollDirection: Axis.horizontal,

                  // IMPORTANT:
                  // Bottom padding gives the shadow enough space.
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    18,
                  ),

                  itemCount: _destinations.length > 5 ? 5 : _destinations.length,

                  itemBuilder: (context, index) {
                    final dest = _destinations[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/destination_detail',
                          arguments: dest,
                        );
                      },

                      child: Container(
                        width: 200,

                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),

                        child: Material(
                          color: Colors.white,

                          elevation: 3,

                          shadowColor:
                              Colors.black.withOpacity(0.14),

                          borderRadius:
                              BorderRadius.circular(20),

                          clipBehavior: Clip.antiAlias,

                          child: SizedBox(
                            height: 248,

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                // ==================================
                                // IMAGE
                                // ==================================

                                SizedBox(
                                  height: 118,
                                  width: double.infinity,

                                  child: Stack(
                                    children: [

                                      // IMAGE
                                      Positioned.fill(
                                        child:
                                            dest['image'] != null &&
                                                    dest['image']
                                                        .toString()
                                                        .startsWith(
                                                          'http',
                                                        )
                                                ? Image.network(
                                                    dest['image'],
                                                    headers: const {
                                                      'ngrok-skip-browser-warning':
                                                          'true',
                                                    },
                                                    fit: BoxFit.cover,

                                                    errorBuilder:
                                                        (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Image.asset(
                                                        'assets/images/other/splashscreen.png',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/other/splashscreen.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                      ),

                                      // ACCESSIBILITY BADGE
                                      Positioned(
                                        left: 10,
                                        bottom: 10,

                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),

                                          decoration:
                                              BoxDecoration(
                                            color: const Color(
                                              0xFFE8F0DF,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              12,
                                            ),
                                          ),

                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [

                                              const Icon(
                                                Icons.accessible,
                                                size: 12,
                                                color: Color(
                                                  0xFF5B7D46,
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 4,
                                              ),

                                              Text(
                                                dest[
                                                        'isHighlyAccessible']
                                                    ? 'Highly Accessible'
                                                    : 'Accessible',

                                                style:
                                                    const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: Color(
                                                    0xFF5B7D46,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ==================================
                                // CARD CONTENT
                                // ==================================

                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      12,
                                      11,
                                      12,
                                      12,
                                    ),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        // DESTINATION NAME
                                        Text(
                                          dest['title'],
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,

                                          style:
                                              const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Color(
                                              0xFF333333,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        // DISTANCE
                                        Row(
                                          children: [

                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Color(
                                                0xFF5B7D46,
                                              ),
                                            ),

                                            const SizedBox(
                                              width: 3,
                                            ),

                                            Text(
                                              dest['distance'] !=
                                                      null
                                                  ? '${dest['distance'].toStringAsFixed(1)} km'
                                                  : '-',

                                              style:
                                                  const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.black54,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // PUSH ICONS TO BOTTOM
                                        const Spacer(),

                                        // ACCESSIBILITY FACILITIES
                                        Row(
                                          children: [

                                            _buildAccessIcon(
                                              Icons.accessible,
                                            ),

                                            const SizedBox(
                                              width: 7,
                                            ),

                                            _buildAccessIcon(
                                              Icons
                                                  .signal_cellular_4_bar,
                                            ),

                                            const SizedBox(
                                              width: 7,
                                            ),

                                            _buildAccessIcon(
                                              Icons.elevator,
                                            ),

                                            const SizedBox(
                                              width: 7,
                                            ),

                                            _buildAccessIcon(
                                              Icons.local_parking,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ====================================================
            // 3. CATEGORIES
            // ====================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                8,
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: const [

                  Text(
                    'Categories',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // CATEGORY GRID
            // ====================================================

            _categories.isEmpty

                ? const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 40,
                    ),

                    child: Center(
                      child: Text(
                        'No categories found',
                      ),
                    ),
                  )

                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      24,
                    ),

                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount:
                        _categories.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),

                          itemBuilder:
                              (context, index) {

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.destinations,
                                  arguments:
                                      _categories[index]
                                          ['title'],
                                );
                              },

                              child: Column(
                                children: [

                                  Container(
                                    padding:
                                        const EdgeInsets.all(
                                      16,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                        0xFFF9FBF5,
                                      ),

                                      borderRadius:
                                          BorderRadius.circular(
                                        16,
                                      ),

                                      border: Border.all(
                                        color: const Color(
                                          0xFFE8F0DF,
                                        ),
                                      ),
                                    ),

                                    child: Icon(
                                      _categories[index]
                                          ['icon'],

                                      color: const Color(
                                        0xFF5B7D46,
                                      ),

                                      size: 24,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    _categories[index]
                                        ['title'],

                                    textAlign:
                                        TextAlign.center,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow.ellipsis,

                                    style:
                                        const TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w500,
                                      color: Color(
                                        0xFF333333,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

            // ====================================================
            // 4. CTA CARD
            // ====================================================

            Padding(
              padding: const EdgeInsets.all(24),

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF0F5EB,
                  ),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Row(
                  children: [

                    Expanded(
                      flex: 6,

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Text(
                            'Plan Your Accessible Trip',

                            style: TextStyle(
                              color: Color(
                                0xFF333333,
                              ),
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'Create a route based on your destinations and accessibility needs.',

                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/route_form',
                              );
                            },

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF5B7D46,
                              ),

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),

                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),

                              elevation: 0,
                            ),

                            child: const Text(
                              'Plan a Route >',

                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      flex: 4,

                      child: Image.asset(
                        'assets/images/mascot/avatar6.png',

                        fit: BoxFit.contain,

                        height: 100,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
            ], // End of else block
          ],
        ),
      ),
    ),
    );
  }

  // ============================================================
  // ACCESSIBILITY ICON
  // ============================================================

  Widget _buildAccessIcon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F3),

        borderRadius:
            BorderRadius.circular(7),

        border: Border.all(
          color: const Color(0xFFE1E6DA),
          width: 1,
        ),
      ),

      child: Icon(
        icon,
        size: 14,
        color: const Color(0xFF6B7565),
      ),
    );
  }
}