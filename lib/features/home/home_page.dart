import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  final List<Map<String, dynamic>> _destinations = [
    {
      'title': 'Botanical Garden',
      'city': 'Bogor',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.5976,
      'lng': 106.7996,
      'distance': null,
      'rating': 4.8,
      'isHighlyAccessible': true,
    },
    {
      'title': 'Ancol Beach',
      'city': 'Jakarta',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.1265,
      'lng': 106.8326,
      'distance': null,
      'rating': 4.5,
      'isHighlyAccessible': false,
    },
    {
      'title': 'Taman Wisata Candi',
      'city': 'Candi Borobudur',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -7.6079,
      'lng': 110.2038,
      'distance': null,
      'isHighlyAccessible': true,
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Nature', 'icon': Icons.park},
    {'title': 'Culture', 'icon': Icons.theater_comedy},
    {'title': 'Shopping', 'icon': Icons.shopping_bag},
    {'title': 'Recreation', 'icon': Icons.attractions},
    {'title': 'Religious', 'icon': Icons.mosque},
    {'title': 'Accommodation', 'icon': Icons.hotel},
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _isLoadingLocation = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _isLoadingLocation = false; });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() { _isLoadingLocation = false; });
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _calculateDistances();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingLocation = false; });
      }
    }
  }

  void _calculateDistances() {
    if (_currentPosition == null) return;
    
    setState(() {
      for (var dest in _destinations) {
        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          dest['lat'],
          dest['lng'],
        );
        dest['distance'] = distanceInMeters / 1000; // Convert to km
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Section
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                image: DecorationImage(
                  image: AssetImage('assets/images/other/hero_image.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar (Menu, Notification, Avatar)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/notification'),
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.notifications_none, size: 24, color: Colors.black87),
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
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              const CircleAvatar(
                                radius: 18,
                                backgroundImage: AssetImage('assets/images/avatar/commoner.png'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Hi, New User 👋',
                        style: TextStyle(
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
            
            // 2. Accessible Places Near You
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accessible Places Near You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.destinations),
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
            SizedBox(
              height: 260, // Height for the card including icons
              child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _destinations.length,
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
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 6,
    offset: const Offset(0, 2),
  ),
],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image with Tag
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.asset(
                                    dest['image'],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0DF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.accessible, size: 12, color: Color(0xFF5B7D46)),
                                        const SizedBox(width: 4),
                                        Text(
                                          dest['isHighlyAccessible'] ? 'Highly Accessible' : 'Accessible',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5B7D46),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Details
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dest['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Color(0xFF5B7D46)),
                                          const SizedBox(width: 2),
                                          Text(
                                            dest['distance'] != null
                                                ? '${dest['distance'].toStringAsFixed(1)} km'
                                                : '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),],
                                  ),
                                  const SizedBox(height: 16),
                                  // Accessibility Icons Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildAccessIcon(Icons.accessible),
                                      const SizedBox(width: 8),
                                      _buildAccessIcon(Icons.signal_cellular_4_bar), // Used as a visual placeholder for ramp
                                      const SizedBox(width: 8),
                                      _buildAccessIcon(Icons.elevator), 
                                      const SizedBox(width: 8),
                                      _buildAccessIcon(Icons.local_parking),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  ),
            ),
            
            // 3. Categories
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.destinations, arguments: _categories[index]['title']),
                    child: Column(
                      children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8F0DF)),
                        ),
                        child: Icon(
                          _categories[index]['icon'],
                          color: const Color(0xFF5B7D46),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _categories[index]['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 4. CTA Card (Plan Your Accessible Trip)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5EB), // Very light green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plan Your Accessible Trip',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a route based on your destinations and accessibility needs.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/route_form');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7D46),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Plan a Route >',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Image.asset(
                        'assets/images/mascot/avatar6.png', // Temporary map placeholder
                        fit: BoxFit.contain,
                        height: 100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: Colors.grey.shade600),
    );
  }
}
