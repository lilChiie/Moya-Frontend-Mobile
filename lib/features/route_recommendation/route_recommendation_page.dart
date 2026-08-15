import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import '../../core/services/route_service.dart';
import '../../core/services/destination_service.dart';
import '../../core/utils/dialog_utils.dart';

class RouteRecommendationPage extends StatefulWidget {
  const RouteRecommendationPage({super.key});

  @override
  State<RouteRecommendationPage> createState() =>
      _RouteRecommendationPageState();
}

class _RouteRecommendationPageState extends State<RouteRecommendationPage> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _destinations = [];
  bool _isLoading = true;

  String _totalDurationStr = '0 Hours';
  String _totalCostStr = 'Free';
  bool _initializedFromArgs = false;
  bool _isRouteSaved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteData();
  }

  Future<void> _syncRouteData() async {
    final userRoute = TripRouteManager().userRoute;
    if (userRoute.isNotEmpty) {
      if (mounted) {
        setState(() {
          _destinations = List.from(userRoute);
          _isLoading = false;
          _recalculateSummary();
        });
      }
      return;
    }

    if (!_initializedFromArgs) {
      _initializedFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        await _parseRouteArguments(args);
        return;
      }
      
      if (mounted) {
        setState(() {
          _destinations = [];
          _isLoading = false;
          _recalculateSummary();
        });
      }
    }
  }

  void _recalculateSummary() {
    int totalMins = 0;
    int totalCost = 0;
    for (var d in _destinations) {
      final timeStr = d['time']?.toString() ?? d['duration']?.toString() ?? '';
      final numMins = int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60;
      totalMins += numMins;
      final fee = d['fee'] is int ? d['fee'] as int : int.tryParse(d['fee']?.toString() ?? '0') ?? 0;
      totalCost += fee;
    }

    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    if (hours > 0 && mins > 0) {
      _totalDurationStr = '$hours hr $mins min';
    } else if (hours > 0) {
      _totalDurationStr = '$hours Hours';
    } else {
      _totalDurationStr = '$mins mins';
    }

    if (totalCost > 0) {
      final formattedCost = totalCost.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
      _totalCostStr = 'Rp $formattedCost';
    } else {
      _totalCostStr = 'Free';
    }
  }

  Future<void> _parseRouteArguments(dynamic args) async {
    setState(() => _isLoading = true);

    // 1. Fetch full destination catalogue so we can enrich destination details (coordinates, photos, fees)
    Map<int, Map<String, dynamic>> destCatalog = {};
    try {
      final catalogResult = await DestinationService().getDestinations();
      if (catalogResult['success'] == true && catalogResult['data'] != null) {
        for (var item in catalogResult['data']) {
          if (item is Map && item['id'] != null) {
            final id = int.tryParse(item['id'].toString());
            if (id != null) {
              destCatalog[id] = Map<String, dynamic>.from(item);
            }
          }
        }
      }
    } catch (_) {}

    List<Map<String, dynamic>> parsedList = [];

    if (args is Map) {
      // Case A: Backend Recommendation API format: { "itinerary": { "items": [...], "total_cost": 130000, "total_duration": 240 } }
      if (args.containsKey('itinerary') && args['itinerary'] is Map) {
        final itineraryMap = args['itinerary'] as Map<String, dynamic>;
        
        if (itineraryMap.containsKey('total_duration')) {
          final totalMins = int.tryParse(itineraryMap['total_duration'].toString()) ?? 0;
          final hours = totalMins ~/ 60;
          final mins = totalMins % 60;
          if (hours > 0 && mins > 0) {
            _totalDurationStr = '$hours hr $mins min';
          } else if (hours > 0) {
            _totalDurationStr = '$hours Hours';
          } else {
            _totalDurationStr = '$totalMins mins';
          }
        }

        if (itineraryMap.containsKey('total_cost')) {
          final costNum = int.tryParse(itineraryMap['total_cost'].toString().split('.').first) ?? 0;
          if (costNum > 0) {
            final formatted = costNum.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]}.',
                );
            _totalCostStr = 'Rp $formatted';
          } else {
            _totalCostStr = 'Free';
          }
        }

        final items = itineraryMap['items'];
        if (items is List) {
          for (var item in items) {
            final destId = int.tryParse(item['destination_id']?.toString() ?? '');
            final catItem = destId != null ? destCatalog[destId] : null;

            final double lat = double.tryParse(catItem?['latitude']?.toString() ?? item['latitude']?.toString() ?? item['lat']?.toString() ?? '') ?? 1.1293;
            final double lng = double.tryParse(catItem?['longitude']?.toString() ?? item['longitude']?.toString() ?? item['lng']?.toString() ?? '') ?? 104.0343;
            final durMins = item['duration_minutes'] ?? catItem?['estimated_duration'] ?? 60;
            final fee = int.tryParse(catItem?['entrance_fee']?.toString() ?? item['entrance_fee']?.toString() ?? '0') ?? 0;
            final img = catItem?['image_url'] ?? item['image_url'];

            parsedList.add({
              'id': destId ?? item['id'],
              'title': item['destination_name'] ?? catItem?['name'] ?? catItem?['title'] ?? item['name'] ?? 'Destinasi',
              'time': item['start_time'] ?? '$durMins mins',
              'lat': lat != 0.0 ? lat : 1.1293,
              'lng': lng != 0.0 ? lng : 104.0343,
              'image_url': img,
              'fee': fee,
              'duration': '$durMins mins',
            });
          }
        }
      }

      // Case B: Direct recommendations list format: { "recommendations": [ ... ] }
      if (parsedList.isEmpty && args.containsKey('recommendations') && args['recommendations'] is List) {
        final recList = args['recommendations'] as List<dynamic>;
        for (var item in recList) {
          final destId = int.tryParse(item['destination_id']?.toString() ?? '');
          final catItem = destId != null ? destCatalog[destId] : null;

          final double lat = double.tryParse(catItem?['latitude']?.toString() ?? '') ?? 1.1293;
          final double lng = double.tryParse(catItem?['longitude']?.toString() ?? '') ?? 104.0343;
          final fee = int.tryParse(catItem?['entrance_fee']?.toString() ?? '0') ?? 0;

          parsedList.add({
            'id': destId ?? item['id'],
            'title': item['destination_name'] ?? catItem?['name'] ?? 'Destinasi',
            'time': '${catItem?['estimated_duration'] ?? 60} mins',
            'lat': lat != 0.0 ? lat : 1.1293,
            'lng': lng != 0.0 ? lng : 104.0343,
            'image_url': catItem?['image_url'],
            'fee': fee,
            'duration': '${catItem?['estimated_duration'] ?? 60} mins',
          });
        }
      }

      // Case C: Standard destinations / route list
      if (parsedList.isEmpty && (args.containsKey('destinations') || args.containsKey('route'))) {
        final list = (args['destinations'] ?? args['route']) as List<dynamic>;
        for (var map in list) {
          if (map is Map) {
            final double lat = double.tryParse(map['latitude']?.toString() ?? map['lat']?.toString() ?? '') ?? 1.1293;
            final double lng = double.tryParse(map['longitude']?.toString() ?? map['lng']?.toString() ?? '') ?? 104.0538;
            final fee = int.tryParse(map['entrance_fee']?.toString() ?? map['fee']?.toString() ?? '0') ?? 0;

            parsedList.add({
              'id': map['id'],
              'title': map['name'] ?? map['title'] ?? 'Destinasi',
              'time': map['time'] ?? map['estimated_time'] ?? '${map['estimated_duration'] ?? 60} mins',
              'lat': lat != 0.0 ? lat : 1.1293,
              'lng': lng != 0.0 ? lng : 104.0538,
              'image_url': map['image_url'],
              'fee': fee,
            });
          }
        }
      }
    } else if (args is List) {
      for (var map in args) {
        if (map is Map) {
          final double lat = double.tryParse(map['latitude']?.toString() ?? map['lat']?.toString() ?? '') ?? 1.1293;
          final double lng = double.tryParse(map['longitude']?.toString() ?? map['lng']?.toString() ?? '') ?? 104.0538;
          final fee = int.tryParse(map['entrance_fee']?.toString() ?? map['fee']?.toString() ?? '0') ?? 0;

          parsedList.add({
            'id': map['id'],
            'title': map['name'] ?? map['title'] ?? 'Destinasi',
            'time': map['time'] ?? '${map['estimated_duration'] ?? 60} mins',
            'lat': lat != 0.0 ? lat : 1.1293,
            'lng': lng != 0.0 ? lng : 104.0538,
            'image_url': map['image_url'],
            'fee': fee,
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _destinations = parsedList;
        _isLoading = false;
        _recalculateSummary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect all latlng points
    final List<LatLng> routePoints = _destinations
        .map((dest) => LatLng(dest['lat'], dest['lng']))
        .toList();

    final LatLng centerPoint = routePoints.isNotEmpty
        ? routePoints.first
        : const LatLng(1.1293, 104.0538);

    return Scaffold(
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
        centerTitle: true,
        title: const Text(
          'Route',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        actions: [
          if (TripRouteManager().userRoute.isNotEmpty || _destinations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reset Custom Route',
              onPressed: () {
                TripRouteManager().clearRoute();
                setState(() {
                  _isRouteSaved = false;
                  _destinations = [];
                  _recalculateSummary();
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // ====================================================
          // MAP LAYER
          // ====================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.moya_mobile',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFF7D9240),
                      strokeWidth: 4.5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _destinations.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final dest = entry.value;
                  return Marker(
                    point: LatLng(dest['lat'], dest['lng']),
                    width: 42,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D9240),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ====================================================
          // DRAGGABLE ITINERARY SUMMARY
          // ====================================================
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // DRAG HANDLE
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // HEADER INFO
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Itinerary Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A2F),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_destinations.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Destinasi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_destinations.length} Destinations',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Jam
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _totalDurationStr,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Harga
                                  Text(
                                    _totalCostStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E3A2F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFF0F0F0),
                                thickness: 1.5,
                              ),
                              const SizedBox(height: 24),
                            ] else ...[
                              Text(
                                'No destinations currently added to your trip route.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Color(0xFFF0F0F0),
                                thickness: 1.5,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // TIMELINE LIST
                    if (_isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF7D9240)),
                          ),
                        ),
                      )
                    else if (_destinations.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE5EDE0), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0DF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.alt_route_rounded,
                                      size: 30,
                                      color: Color(0xFF7D9240),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No Route Added Yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E3A2F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You don\'t have any active destinations in your route. Generate an AI trip plan or add places from Explore.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/route_form');
                                    },
                                    icon: const Icon(Icons.auto_awesome, size: 17),
                                    label: const Text(
                                      'Plan Your Trip',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7D9240),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/destinations');
                                    },
                                    icon: const Icon(Icons.explore_outlined, size: 17, color: Color(0xFF7D9240)),
                                    label: const Text(
                                      'Explore Destinations',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF7D9240),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF7D9240), width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dest = _destinations[index];
                              final isLast =
                                  index == _destinations.length - 1;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Number and Line Column
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F5EA),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Color(0xFF7D9240),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: const Color(0xFFE8F0DF),
                                                margin: const EdgeInsets.symmetric(
                                                    vertical: 4),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Destination Details Column
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 32.0, top: 4.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    dest['title'] ?? 'Destinasi',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF1E3A2F),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    dest['time'] ?? '1-2 Hours',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (TripRouteManager().userRoute.isNotEmpty)
                                              IconButton(
                                                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                                                onPressed: () {
                                                  TripRouteManager().removeDestination(index);
                                                  _syncRouteData();
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _destinations.length,
                          ),
                        ),
                      ),

                    // ACTION BUTTONS: SAVE ROUTE THEN FINISH TRIP
                    if (_destinations.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                          child: !_isRouteSaved
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await SavedRouteManager().saveCurrentRoute(
                                      destinations: _destinations,
                                      totalDuration: _totalDurationStr,
                                      totalCost: _totalCostStr,
                                    );
                                    setState(() => _isRouteSaved = true);
                                    if (!context.mounted) return;
                                    AppDialogs.showStatusDialog(
                                      context: context,
                                      isSuccess: true,
                                      title: 'Route Saved',
                                      message: 'Your route has been saved successfully! The Finish Trip button is now active.',
                                      buttonText: 'OK',
                                      onPressed: () => Navigator.pop(context),
                                    );
                                  },
                                  icon: const Icon(Icons.bookmark_add_outlined, size: 19),
                                  label: const Text(
                                    'Save Route',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7D9240),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('This route is already saved in your saved routes history.'),
                                          backgroundColor: Color(0xFF5B7D46),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.check, size: 16, color: Color(0xFF7D9240)),
                                    label: const Text(
                                      'Saved',
                                      style: TextStyle(
                                        color: Color(0xFF7D9240),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF7D9240), width: 1.5),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        if (_destinations.isEmpty) return;

                                        // 1. Add all destinations in this route to History
                                        await DestinationHistoryManager().addDestinations(_destinations);

                                        // 2. Clear active custom route
                                        TripRouteManager().clearRoute();

                                        if (!context.mounted) return;
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFE8F0DF),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.emoji_events_outlined,
                                                      color: Color(0xFF5B7D46),
                                                      size: 40,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  const Text(
                                                    'Trip Completed!',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E3A2F),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'All ${_destinations.length} destinations on this route have been successfully added to your destination history.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            Navigator.pop(ctx);
                                                            Navigator.pop(context);
                                                          },
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: Colors.grey.shade700,
                                                            side: BorderSide(color: Colors.grey.shade300),
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                          ),
                                                          child: const Text('Back'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(ctx);
                                                            Navigator.pushReplacementNamed(
                                                              context,
                                                              '/destinations',
                                                              arguments: {'tab': 'history'},
                                                            );
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF7D9240),
                                                            foregroundColor: Colors.white,
                                                            elevation: 0,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'View History',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text(
                                        'Finish Trip',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7D9240),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
