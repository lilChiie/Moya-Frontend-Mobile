import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  bool _argsInitialized = false;

  final List<String> _allCategories = [
    'Nature',
    'Culture',
    'Shopping',
    'Recreation',
    'Religious',
    'Accommodation',
  ];

  final List<Map<String, dynamic>> _destinations = [
    {
      'title': 'Botanical Garden',
      'category': 'Nature',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.5976,
      'lng': 106.7996,
      'distance': null,
      'isHighlyAccessible': true,
    },
    {
      'title': 'Ancol Beach',
      'category': 'Recreation',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.1265,
      'lng': 106.8326,
      'distance': null,
      'isHighlyAccessible': false,
    },
    {
      'title': 'Taman Wisata Candi',
      'category': 'Culture',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -7.6079,
      'lng': 110.2038,
      'distance': null,
      'isHighlyAccessible': true,
    },
    {
      'title': 'Istiqlal Mosque',
      'category': 'Religious',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.1702,
      'lng': 106.8310,
      'distance': null,
      'isHighlyAccessible': true,
    },
    {
      'title': 'Grand Indonesia',
      'category': 'Shopping',
      'image': 'assets/images/other/splashscreen.png',
      'lat': -6.1950,
      'lng': 106.8208,
      'distance': null,
      'isHighlyAccessible': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_argsInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is String && args.isNotEmpty) {
        _selectedCategories.add(args);
      }

      _argsInitialized = true;
    }
  }

  // =========================================================
  // LOCATION
  // =========================================================

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _calculateDistances();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _calculateDistances() {
    if (_currentPosition == null) return;

    setState(() {
      for (final dest in _destinations) {
        final double distanceInMeters =
            Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          dest['lat'],
          dest['lng'],
        );

        dest['distance'] = distanceInMeters / 1000;
      }
    });
  }

  // =========================================================
  // FILTER
  // =========================================================

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2F),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _allCategories.map((category) {
                      final bool isSelected =
                          _selectedCategories
                              .contains(category);

                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor:
                            const Color(0xFFE8F0DF),
                        checkmarkColor:
                            const Color(0xFF5B7D46),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              if (!_selectedCategories
                                  .contains(category)) {
                                _selectedCategories
                                    .add(category);
                              }
                            } else {
                              _selectedCategories
                                  .remove(category);
                            }
                          });

                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7D9240),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          const Text('Apply Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ACCESSIBILITY ICON
  // =========================================================

  Widget _buildAccessIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: Colors.grey.shade600,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>>
        filteredDestinations =
        _destinations.where((dest) {
      final bool matchesSearch = dest['title']
          .toString()
          .toLowerCase()
          .contains(
            _searchQuery.toLowerCase(),
          );

      final bool matchesCategory =
          _selectedCategories.isEmpty ||
              _selectedCategories
                  .contains(dest['category']);

      return matchesSearch && matchesCategory;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Status bar background
        statusBarColor: Colors.transparent,

        // Android
        statusBarIconBrightness: Brightness.light,

        // iOS
        statusBarBrightness: Brightness.dark,

        // Bottom navigation area
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,

        // =====================================================
        // APP BAR
        // =====================================================

        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: const Color(0xFF7D9240),
          foregroundColor: Colors.white,

          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,

          automaticallyImplyLeading: false,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: const Text(
            'Destinations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Title CENTER
          centerTitle: true,
        ),

        // =====================================================
        // BODY
        // =====================================================

        body: Column(
          children: [
            // ===================================================
            // SEARCH + FILTER
            // ===================================================

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF9FBF5),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFFE8F0DF),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Search destinations...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  InkWell(
                    onTap: _showFilterBottomSheet,
                    borderRadius:
                        BorderRadius.circular(12),
                    child: Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _selectedCategories
                                    .isNotEmpty
                                ? const Color(
                                    0xFF7D9240,
                                  )
                                : const Color(
                                    0xFFF9FBF5,
                                  ),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedCategories
                                      .isNotEmpty
                                  ? const Color(
                                      0xFF7D9240,
                                    )
                                  : const Color(
                                      0xFFE8F0DF,
                                    ),
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        color:
                            _selectedCategories
                                    .isNotEmpty
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===================================================
            // DESTINATION LIST
            // ===================================================

            Expanded(
              child: _isLoadingLocation
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color: Color(0xFF7D9240),
                      ),
                    )
                  : filteredDestinations.isEmpty
                      ? const Center(
                          child: Text(
                            'No destinations found',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount:
                              filteredDestinations.length,
                          itemBuilder:
                              (context, index) {
                            final dest =
                                filteredDestinations[
                                    index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/destination_detail',
                                  arguments: dest,
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  bottom: 20,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(
                                        0.06,
                                      ),
                                      blurRadius: 12,
                                      offset:
                                          const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    // =================================
                                    // IMAGE
                                    // =================================

                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius
                                                  .vertical(
                                            top: Radius
                                                .circular(
                                              20,
                                            ),
                                          ),
                                          child:
                                              Image.asset(
                                            dest['image'],
                                            height: 180,
                                            width:
                                                double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          child:
                                              Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal:
                                                  10,
                                              vertical: 6,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  const Color(
                                                0xFFE8F0DF,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                12,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .accessible,
                                                  size: 14,
                                                  color:
                                                      Color(
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
                                                    fontSize:
                                                        12,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        Color(
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

                                    // =================================
                                    // DESTINATION DETAILS
                                    // =================================

                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            dest['title'],
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize: 16,
                                              color:
                                                  Color(
                                                0xFF1E3A2F,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                          ),

                                          const SizedBox(
                                            height: 12,
                                          ),

                                          Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .location_on,
                                                size: 16,
                                                color:
                                                    Color(
                                                  0xFF5B7D46,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Text(
                                                dest['distance'] !=
                                                        null
                                                    ? '${dest['distance'].toStringAsFixed(1)} km'
                                                    : '-',
                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      14,
                                                  color:
                                                      Colors.black54,
                                                  fontWeight:
                                                      FontWeight
                                                          .w500,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 16,
                                          ),

                                          Row(
                                            children: [
                                              _buildAccessIcon(
                                                Icons
                                                    .accessible,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              _buildAccessIcon(
                                                Icons
                                                    .signal_cellular_4_bar,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              _buildAccessIcon(
                                                Icons
                                                    .elevator,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              _buildAccessIcon(
                                                Icons
                                                    .local_parking,
                                              ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 20,
                                          ),

                                          SizedBox(
                                            width:
                                                double.infinity,
                                            child:
                                                ElevatedButton(
                                              onPressed: () {
                                                // Add to route logic
                                              },
                                              style:
                                                  ElevatedButton
                                                      .styleFrom(
                                                backgroundColor:
                                                    const Color(
                                                  0xFF7D9240,
                                                ),
                                                foregroundColor:
                                                    Colors
                                                        .white,
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  vertical:
                                                      12,
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    12,
                                                  ),
                                                ),
                                                elevation:
                                                    0,
                                              ),
                                              child:
                                                  const Text(
                                                'Add to Route',
                                                style:
                                                    TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                ),
                                              ),
                                            ),
                                          ),
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
          ],
        ),
      ),
    );
  }
}