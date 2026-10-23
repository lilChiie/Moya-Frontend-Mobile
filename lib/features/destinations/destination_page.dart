import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/destination_service.dart';
import '../../core/services/tourism_service.dart';
import '../../core/services/route_service.dart';
import '../../core/utils/dialog_utils.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  Position? _currentPosition;
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  bool _argsInitialized = false;
  int _initialTabIndex = 0;

  List<String> _allCategories = [];
  Map<int, String> _tourismCategoriesMap = {};

  List<Map<String, dynamic>> _destinations = [];
  bool _isLoadingDestinations = true;

  List<Map<String, dynamic>> _historyDestinations = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      _argsInitialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _selectedCategories = [args];
      } else if (args is Map) {
        if (args.containsKey('category') && args['category'] is String) {
          _selectedCategories = [args['category']];
        }
        if (args['tab'] == 'history') {
          _initialTabIndex = 1;
        }
      }
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final list = await DestinationHistoryManager().getHistory();
    if (mounted) {
      setState(() {
        _historyDestinations = list;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadData() async {
    final tourismService = TourismService();
    final result = await tourismService.getTourismCategories();
    
    if (result['success'] && result['data'] != null) {
      final List<dynamic> data = result['data'];
      _tourismCategoriesMap = {
        for (var e in data) e['id'] as int: e['name'] ?? e['title'] ?? 'Unknown'
      };
      
      if (mounted) {
        setState(() {
          _allCategories = _tourismCategoriesMap.values.toList();
        });
      }
    }
    
    await _fetchDestinations();
  }

  Future<void> _fetchDestinations() async {
    final destinationService = DestinationService();
    final result = await destinationService.getDestinations();

    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final List<dynamic> data = result['data'];
          _destinations = data.map((e) {
            final double lat = double.tryParse(e['latitude'].toString()) ?? 0.0;
            final double lng = double.tryParse(e['longitude'].toString()) ?? 0.0;
            
            final List<dynamic>? tourismIds = e['tourism_id'];
            List<String> categories = [];
            if (tourismIds != null) {
              for (var id in tourismIds) {
                if (id is int && _tourismCategoriesMap.containsKey(id)) {
                  categories.add(_tourismCategoriesMap[id]!);
                }
              }
            }
            if (categories.isEmpty) categories.add('Nature');
            
            return {
              'id': e['id'],
              'title': e['name'] ?? 'Unknown',
              'categories': categories,
              'image': e['image_url'] != null ? e['image_url'].toString().replaceFirst('http://', 'https://') : null,
              'lat': lat,
              'lng': lng,
              'distance': null,
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
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Failed to load destinations.')),
        );
      }
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
      }

      _calculateDistances();
    } catch (e) {
      // Ignore location fetch errors
    }
  }

  void _calculateDistances() {
    if (_currentPosition == null) return;

    setState(() {
      for (var dest in _destinations) {
        if (dest['lat'] != 0.0 && dest['lng'] != 0.0) {
          double distanceInMeters = Geolocator.distanceBetween(
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

      final List<String> destCategories = dest['categories'] as List<String>? ?? [];
      final bool matchesCategory =
          _selectedCategories.isEmpty ||
              destCategories.any((c) => _selectedCategories.contains(c));

      return matchesSearch && matchesCategory;
    }).toList();

    return DefaultTabController(
      key: ValueKey(_initialTabIndex),
      initialIndex: _initialTabIndex,
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
        // Status bar background
        statusBarColor: Colors.transparent,

        // Android
        statusBarIconBrightness: Brightness.light,

        // iOS
        statusBarBrightness: Brightness.dark,

        // Bottom navigation area
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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
          centerTitle: true,
        ),

        // =====================================================
        // BODY
        // =====================================================

        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Color(0xFF7D9240),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF7D9240),
                  tabs: [
                    Tab(text: 'Explore'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
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
              child: _isLoadingDestinations
                  ? const Center(
                      child: CircularProgressIndicator(
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
                      : RefreshIndicator(
                          color: const Color(0xFF7D9240),
                          onRefresh: () async {
                            setState(() {
                              _isLoadingDestinations = true;
                              // location loading doesn't block UI
                            });
                            _getCurrentLocation(); // fire and forget
                            await _loadData();
                          },
                          child: ListView.builder(
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
                            final destCategories = (dest['categories'] is List)
                                ? (dest['categories'] as List).cast<String>()
                                : <String>['Wisata'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // =================================
                                  // CLICKABLE CARD HEADER & DETAILS
                                  // =================================
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/destination_detail',
                                        arguments: dest,
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // IMAGE
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                              child: Container(
                                                height: 180,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  image: dest['image'] != null && dest['image'].toString().startsWith('http')
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                            dest['image'],
                                                            headers: const {
                                                              'ngrok-skip-browser-warning': 'true',
                                                            },
                                                          ),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const DecorationImage(
                                                          image: AssetImage('assets/images/other/splashscreen.png'),
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F0DF),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.accessible,
                                                      size: 14,
                                                      color: Color(0xFF5B7D46),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      dest['isHighlyAccessible']
                                                          ? 'Highly Accessible'
                                                          : 'Accessible',
                                                      style: const TextStyle(
                                                        fontSize: 12,
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

                                        // DETAILS (Title, category, distance, icons)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dest['title'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1E3A2F),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      destCategories.join(', '),
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                children: [
                                                  _buildAccessIcon(Icons.accessible),
                                                  const SizedBox(width: 8),
                                                  _buildAccessIcon(Icons.signal_cellular_4_bar),
                                                  const SizedBox(width: 8),
                                                  _buildAccessIcon(Icons.elevator),
                                                  const SizedBox(width: 8),
                                                  _buildAccessIcon(Icons.local_parking),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // =================================
                                  // ADD TO ROUTE BUTTON
                                  // =================================
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final title = dest['title'] ?? dest['name'] ?? 'Destinasi';
                                          TripRouteManager().addDestination({
                                            'id': dest['id'],
                                            'title': title,
                                            'latitude': dest['lat'] ?? dest['latitude'],
                                            'longitude': dest['lng'] ?? dest['longitude'],
                                            'estimated_duration': dest['estimated_duration'] ?? dest['duration'],
                                            'entrance_fee': dest['entrance_fee'] ?? dest['fee'],
                                            'image_url': dest['image_url'] ?? dest['image'],
                                          });

                                          AppDialogs.showStatusDialog(
                                            context: context,
                                            isSuccess: true,
                                            title: 'Added to Route',
                                            message: '$title has been added to your route.',
                                            buttonText: 'View Route',
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.pushNamed(context, '/route_recommendation');
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.add_road, size: 18),
                                        label: const Text(
                                          'Add to Route',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF7D9240),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                         ),
                      ),
            ),
                    ],
                  ),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7D9240)),
      );
    }

    if (_historyDestinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F5EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, size: 48, color: Color(0xFF7D9240)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum Ada Riwayat Destinasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A2F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selesaikan rute perjalanan (tekan tombol Finish Trip pada halaman rute) untuk mencatat destinasi yang telah Anda kunjungi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7D9240),
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyDestinations.length,
        itemBuilder: (context, index) {
          final dest = _historyDestinations[index];
          final imgUrl = dest['image_url'] ?? dest['image'];
          final formattedImg = (imgUrl != null && imgUrl.toString().trim().isNotEmpty)
              ? (imgUrl.toString().startsWith('http')
                  ? imgUrl.toString()
                  : '${ApiConstants.baseUrl}${imgUrl.toString().startsWith('/') ? '' : '/'}$imgUrl')
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F0DF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/destination_detail',
                  arguments: dest,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: formattedImg != null
                          ? Image.network(
                              formattedImg,
                              headers: const {'ngrok-skip-browser-warning': 'true'},
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 85,
                                height: 85,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Image.asset(
                              'assets/images/other/splashscreen.png',
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0DF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Color(0xFF5B7D46)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5B7D46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (dest['visited_at'] != null)
                                Text(
                                  dest['visited_at'].toString().split('•').first.trim(),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dest['title'] ?? dest['name'] ?? 'Destinasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A2F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest['category'] ?? 'Wisata Inklusif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
