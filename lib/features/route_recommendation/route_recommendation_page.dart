import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import '../../core/services/route_service.dart';
import '../../core/services/road_route_service.dart';
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

  // Actual Road Route State
  List<LatLng> _roadPoints = [];
  bool _isLoadingRoad = false;
  double _roadDistanceMeters = 0;
  double _roadDurationSeconds = 0;
  bool _isActualRoadRoute = false;
  String _lastFetchedRouteKey = '';
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;
  bool _navigating = false;
  bool _startingNavigation = false;
  int _nextDestination = 0;
  int _routeRequest = 0;
  DateTime? _lastNavigationFetch;

  void _stopNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _routeRequest++;
    _navigating = false;
    _isLoadingRoad = false;
    _lastFetchedRouteKey = '';
  }

  @override
  void dispose() {
    _stopNavigation();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    setState(() => _startingNavigation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on GPS to start navigation.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception(
          'Location access is required. Enable it in your app settings.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));
      if (!mounted || _destinations.isEmpty) return;
      setState(() {
        _navigating = true;
        if (_nextDestination >= _destinations.length) _nextDestination = 0;
        _lastNavigationFetch = null;
      });
      _onPosition(position);
      if (!_navigating) return;
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        _onPosition,
        onError: (Object error) {
          if (!mounted) return;
          setState(_stopNavigation);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location tracking has stopped. Please tap Start to try again.',
              ),
            ),
          );
          _fetchRoadRoute();
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error is TimeoutException
                ? 'Finding your location is taking longer than usual. Please try again.'
                : 'We couldn’t start navigation. Turn on location services and allow location access, then try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingNavigation = false);
    }
  }

  void _onPosition(Position position) {
    if (!mounted || !_navigating || _nextDestination >= _destinations.length) {
      return;
    }
    final point = LatLng(position.latitude, position.longitude);
    final destination = _destinations[_nextDestination];
    final arrived =
        position.accuracy <= 50 &&
        Geolocator.distanceBetween(
              point.latitude,
              point.longitude,
              (destination['lat'] as num).toDouble(),
              (destination['lng'] as num).toDouble(),
            ) <=
            50;
    setState(() {
      _currentPosition = point;
      if (arrived) _nextDestination++;
    });
    _mapController.move(point, 16);
    if (arrived) {
      unawaited(DestinationHistoryManager().addDestinations([destination]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You’ve arrived at ${destination['title']}.')),
      );
      if (_nextDestination == _destinations.length) {
        setState(() {
          _stopNavigation();
          _roadPoints = [point];
          _roadDistanceMeters = 0;
          _roadDurationSeconds = 0;
        });
        return;
      }
    }
    final now = DateTime.now();
    if (arrived ||
        _lastNavigationFetch == null ||
        now.difference(_lastNavigationFetch!) >= const Duration(seconds: 10)) {
      _lastNavigationFetch = now;
      _fetchRoadRoute();
    }
  }

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
        _fetchRoadRoute();
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
        _fetchRoadRoute();
      }
    }
  }

  Future<void> _fetchRoadRoute() async {
    final waypoints =
        _destinations
            .skip(_navigating ? _nextDestination : 0)
            .map((dest) => LatLng(dest['lat'], dest['lng']))
            .toList();
    if (_navigating && _currentPosition != null) {
      waypoints.insert(0, _currentPosition!);
    }

    final currentKey = waypoints
        .map(
          (p) =>
              '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}',
        )
        .join(';');
    if (currentKey == _lastFetchedRouteKey && _roadPoints.isNotEmpty) {
      return;
    }
    _lastFetchedRouteKey = currentKey;
    final request = ++_routeRequest;

    if (waypoints.isEmpty) {
      if (mounted) {
        setState(() {
          _roadPoints = [];
          _isLoadingRoad = false;
          _roadDistanceMeters = 0;
          _roadDurationSeconds = 0;
          _isActualRoadRoute = false;
        });
      }
      return;
    }

    if (waypoints.length == 1) {
      if (mounted) {
        setState(() {
          _roadPoints = waypoints;
          _isLoadingRoad = false;
          _roadDistanceMeters = 0;
          _roadDurationSeconds = 0;
          _isActualRoadRoute = true;
        });
        _fitMapCamera(waypoints);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingRoad = true;
      });
    }

    final result = await RoadRouteService().getRoadRoute(waypoints);

    if (mounted && request == _routeRequest) {
      setState(() {
        _roadPoints = result.coordinates;
        _roadDistanceMeters = result.totalDistanceMeters;
        _roadDurationSeconds = result.totalDurationSeconds;
        _isActualRoadRoute = result.isActualRoad;
        _isLoadingRoad = false;
      });

      if (!_navigating) {
        _fitMapCamera(_roadPoints.isNotEmpty ? _roadPoints : waypoints);
      }
    }
  }

  void _fitMapCamera(List<LatLng> points) {
    if (points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (points.length == 1) {
          _mapController.move(points.first, 14.0);
        } else {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(
                left: 40,
                right: 40,
                top: 75,
                bottom: 250,
              ),
            ),
          );
        }
      } catch (_) {}
    });
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return '0 km';
    if (meters >= 1000) {
      return '${(meters / 1000.0).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(double seconds) {
    final mins = (seconds / 60.0).round();
    if (mins <= 0) return '1 min';
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    if (hours > 0 && remainingMins > 0) {
      return '$hours hr $remainingMins min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$mins min';
    }
  }

  void _recalculateSummary() {
    int totalMins = 0;
    int totalCost = 0;
    for (var d in _destinations) {
      final timeStr = d['time']?.toString() ?? d['duration']?.toString() ?? '';
      final numMins =
          int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60;
      totalMins += numMins;
      final fee =
          d['fee'] is int
              ? d['fee'] as int
              : int.tryParse(d['fee']?.toString() ?? '0') ?? 0;
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
          final totalMins =
              int.tryParse(itineraryMap['total_duration'].toString()) ?? 0;
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
          final costNum =
              int.tryParse(
                itineraryMap['total_cost'].toString().split('.').first,
              ) ??
              0;
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
            final destId = int.tryParse(
              item['destination_id']?.toString() ?? '',
            );
            final catItem = destId != null ? destCatalog[destId] : null;

            final double lat =
                double.tryParse(
                  catItem?['latitude']?.toString() ??
                      item['latitude']?.toString() ??
                      item['lat']?.toString() ??
                      '',
                ) ??
                1.1293;
            final double lng =
                double.tryParse(
                  catItem?['longitude']?.toString() ??
                      item['longitude']?.toString() ??
                      item['lng']?.toString() ??
                      '',
                ) ??
                104.0343;
            final durMins =
                item['duration_minutes'] ??
                catItem?['estimated_duration'] ??
                60;
            final fee =
                int.tryParse(
                  catItem?['entrance_fee']?.toString() ??
                      item['entrance_fee']?.toString() ??
                      '0',
                ) ??
                0;
            final img = catItem?['image_url'] ?? item['image_url'];

            parsedList.add({
              'id': destId ?? item['id'],
              'title':
                  item['destination_name'] ??
                  catItem?['name'] ??
                  catItem?['title'] ??
                  item['name'] ??
                  'Destination',
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
      if (parsedList.isEmpty &&
          args.containsKey('recommendations') &&
          args['recommendations'] is List) {
        final recList = args['recommendations'] as List<dynamic>;
        for (var item in recList) {
          final destId = int.tryParse(item['destination_id']?.toString() ?? '');
          final catItem = destId != null ? destCatalog[destId] : null;

          final double lat =
              double.tryParse(catItem?['latitude']?.toString() ?? '') ?? 1.1293;
          final double lng =
              double.tryParse(catItem?['longitude']?.toString() ?? '') ??
              104.0343;
          final fee =
              int.tryParse(catItem?['entrance_fee']?.toString() ?? '0') ?? 0;

          parsedList.add({
            'id': destId ?? item['id'],
            'title':
                item['destination_name'] ?? catItem?['name'] ?? 'Destination',
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
      if (parsedList.isEmpty &&
          (args.containsKey('destinations') || args.containsKey('route'))) {
        final list = (args['destinations'] ?? args['route']) as List<dynamic>;
        for (var map in list) {
          if (map is Map) {
            final double lat =
                double.tryParse(
                  map['latitude']?.toString() ?? map['lat']?.toString() ?? '',
                ) ??
                1.1293;
            final double lng =
                double.tryParse(
                  map['longitude']?.toString() ?? map['lng']?.toString() ?? '',
                ) ??
                104.0538;
            final fee =
                int.tryParse(
                  map['entrance_fee']?.toString() ??
                      map['fee']?.toString() ??
                      '0',
                ) ??
                0;

            parsedList.add({
              'id': map['id'],
              'title': map['name'] ?? map['title'] ?? 'Destination',
              'time':
                  map['time'] ??
                  map['estimated_time'] ??
                  '${map['estimated_duration'] ?? 60} mins',
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
          final double lat =
              double.tryParse(
                map['latitude']?.toString() ?? map['lat']?.toString() ?? '',
              ) ??
              1.1293;
          final double lng =
              double.tryParse(
                map['longitude']?.toString() ?? map['lng']?.toString() ?? '',
              ) ??
              104.0538;
          final fee =
              int.tryParse(
                map['entrance_fee']?.toString() ??
                    map['fee']?.toString() ??
                    '0',
              ) ??
              0;

          parsedList.add({
            'id': map['id'],
            'title': map['name'] ?? map['title'] ?? 'Destination',
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
      _fetchRoadRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect destination waypoint points
    final List<LatLng> waypoints =
        _destinations.map((dest) => LatLng(dest['lat'], dest['lng'])).toList();

    // Prefer actual road network polyline if loaded; fallback to direct waypoints
    final List<LatLng> displayPoints =
        _roadPoints.isNotEmpty ? _roadPoints : waypoints;

    final LatLng centerPoint =
        waypoints.isNotEmpty ? waypoints.first : const LatLng(1.1293, 104.0538);

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
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (TripRouteManager().userRoute.isNotEmpty ||
              _destinations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reset Custom Route',
              onPressed: () {
                _stopNavigation();
                _nextDestination = 0;
                TripRouteManager().clearRoute();
                setState(() {
                  _isRouteSaved = false;
                  _destinations = [];
                  _roadPoints = [];
                  _roadDistanceMeters = 0;
                  _roadDurationSeconds = 0;
                  _isActualRoadRoute = false;
                  _lastFetchedRouteKey = '';
                  _recalculateSummary();
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // ====================================================
          // MAP LAYER (OPENSTREETMAP + ACTUAL ROAD NETWORK POLYLINE)
          // ====================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: centerPoint, initialZoom: 12.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.moya_mobile',
              ),
              if (displayPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer subtle casing for road contrast
                    Polyline(
                      points: displayPoints,
                      color: const Color(0xFF1E3A2F).withValues(alpha: 0.18),
                      strokeWidth: 7.5,
                    ),
                    // Main road polyline following actual highway & street geometry
                    Polyline(
                      points: displayPoints,
                      color: const Color(0xFF5B7D46),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers:
                    _destinations.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final dest = entry.value;
                      final bool isStart = index == 0;
                      final bool isEnd =
                          index == _destinations.length - 1 &&
                          _destinations.length > 1;

                      return Marker(
                        point: LatLng(dest['lat'], dest['lng']),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            _mapController.move(
                              LatLng(dest['lat'], dest['lng']),
                              15.0,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  index < _nextDestination
                                      ? Colors.grey
                                      : isStart
                                      ? const Color(0xFF388E3C)
                                      : isEnd
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF7D9240),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 6,
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
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),

          // ====================================================
          // FLOATING MAP CONTROLS & ROAD ROUTE STATUS
          // ====================================================
          if (_isLoadingRoad)
            Positioned(
              top: 14,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF5B7D46),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Finding a road route...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_destinations.length >= 2)
            Positioned(
              top: 14,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5EDE0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isActualRoadRoute
                          ? Icons.alt_route_rounded
                          : Icons.timeline_rounded,
                      size: 16,
                      color: const Color(0xFF5B7D46),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isActualRoadRoute
                          ? 'Road Route • ${_formatDistance(_roadDistanceMeters)}${_roadDurationSeconds > 0 ? " (${_formatDuration(_roadDurationSeconds)})" : ""}'
                          : 'Direct Route • ${_formatDistance(_roadDistanceMeters)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A2F),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Fit-Route button
          if (displayPoints.isNotEmpty)
            Positioned(
              top: 14,
              right: 16,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _fitMapCamera(displayPoints);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: Color(0xFF1E3A2F),
                      size: 20,
                    ),
                  ),
                ),
              ),
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
                              Text(
                                _navigating
                                    ? 'Heading to: ${_destinations[_nextDestination]['title']} • $_nextDestination/${_destinations.length} visited'
                                    : _nextDestination == _destinations.length
                                    ? 'You’ve visited all destinations'
                                    : 'Start navigation from your current location',
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed:
                                    _startingNavigation
                                        ? null
                                        : () {
                                          if (_navigating) {
                                            setState(_stopNavigation);
                                            _fetchRoadRoute();
                                          } else {
                                            _startNavigation();
                                          }
                                        },
                                icon: Icon(
                                  _navigating ? Icons.stop : Icons.navigation,
                                ),
                                label: Text(
                                  _startingNavigation
                                      ? 'Finding your location…'
                                      : _navigating
                                      ? 'Stop'
                                      : 'Start',
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_destinations.isNotEmpty) ...[
                              Row(
                                children: [
                                  // Destinasi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_destinations.length} Destinations',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_roadDistanceMeters > 0) ...[
                                    const SizedBox(width: 14),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions_car_outlined,
                                          size: 16,
                                          color: Color(0xFF5B7D46),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatDistance(_roadDistanceMeters)}${_roadDurationSeconds > 0 ? " • ${_formatDuration(_roadDurationSeconds)}" : ""}',
                                          style: const TextStyle(
                                            color: Color(0xFF5B7D46),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Spacer(),
                                  // Jam
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _totalDurationStr,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isActualRoadRoute
                                            ? Icons.alt_route_rounded
                                            : Icons.straighten_rounded,
                                        size: 15,
                                        color:
                                            _isActualRoadRoute
                                                ? const Color(0xFF5B7D46)
                                                : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _isActualRoadRoute
                                            ? 'Following roads'
                                            : 'Direct route',
                                        style: TextStyle(
                                          color:
                                              _isActualRoadRoute
                                                  ? const Color(0xFF5B7D46)
                                                  : Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                            child: CircularProgressIndicator(
                              color: Color(0xFF7D9240),
                            ),
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
                              border: Border.all(
                                color: const Color(0xFFE5EDE0),
                                width: 1.5,
                              ),
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
                                      Navigator.pushNamed(
                                        context,
                                        '/route_form',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 17,
                                    ),
                                    label: const Text(
                                      'Plan Your Trip',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7D9240),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
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
                                      Navigator.pushNamed(
                                        context,
                                        '/destinations',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.explore_outlined,
                                      size: 17,
                                      color: Color(0xFF7D9240),
                                    ),
                                    label: const Text(
                                      'Explore Destinations',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF7D9240),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF7D9240),
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final dest = _destinations[index];
                            final isLast = index == _destinations.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
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
                                        bottom: 32.0,
                                        top: 4.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dest['title'] ?? 'Destination',
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
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red.shade300,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              if (TripRouteManager()
                                                  .userRoute
                                                  .isNotEmpty) {
                                                TripRouteManager()
                                                    .removeDestination(index);
                                                _syncRouteData();
                                              } else {
                                                setState(() {
                                                  _destinations.removeAt(index);
                                                  _recalculateSummary();
                                                });
                                                _fetchRoadRoute();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }, childCount: _destinations.length),
                        ),
                      ),

                    // ACTION BUTTONS: SAVE ROUTE THEN FINISH TRIP
                    if (_destinations.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                          child:
                              !_isRouteSaved
                                  ? SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await SavedRouteManager()
                                            .saveCurrentRoute(
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
                                          message:
                                              'Your route has been saved successfully! The Finish Trip button is now active.',
                                          buttonText: 'OK',
                                          onPressed:
                                              () => Navigator.pop(context),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.bookmark_add_outlined,
                                        size: 19,
                                      ),
                                      label: const Text(
                                        'Save Route',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF7D9240,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'This route is already saved in your saved routes history.',
                                              ),
                                              backgroundColor: Color(
                                                0xFF5B7D46,
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF7D9240),
                                        ),
                                        label: const Text(
                                          'Saved',
                                          style: TextStyle(
                                            color: Color(0xFF7D9240),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF7D9240),
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _navigating || _nextDestination < _destinations.length
                                                  ? null
                                                  : () async {
                                                    if (_destinations.isEmpty) {
                                                      return;
                                                    }

                                                    // 2. Clear active custom route
                                                    TripRouteManager()
                                                        .clearRoute();

                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder:
                                                          (ctx) => Dialog(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    24,
                                                                  ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          16,
                                                                        ),
                                                                    decoration: const BoxDecoration(
                                                                      color: Color(
                                                                        0xFFE8F0DF,
                                                                      ),
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons
                                                                          .emoji_events_outlined,
                                                                      color: Color(
                                                                        0xFF5B7D46,
                                                                      ),
                                                                      size: 40,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 18,
                                                                  ),
                                                                  const Text(
                                                                    'Trip Completed!',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color(
                                                                        0xFF1E3A2F,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Text(
                                                                    'All ${_destinations.length} destinations on this route have been successfully added to your destination history.',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color:
                                                                          Colors
                                                                              .grey
                                                                              .shade600,
                                                                      height:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 24,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: OutlinedButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(
                                                                              ctx,
                                                                            );
                                                                            Navigator.pop(
                                                                              context,
                                                                            );
                                                                          },
                                                                          style: OutlinedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.grey.shade700,
                                                                            side: BorderSide(
                                                                              color:
                                                                                  Colors.grey.shade300,
                                                                            ),
                                                                            padding: const EdgeInsets.symmetric(
                                                                              vertical:
                                                                                  12,
                                                                            ),
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                12,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          child: const Text(
                                                                            'Back',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            12,
                                                                      ),
                                                                      Expanded(
                                                                        child: ElevatedButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(
                                                                              ctx,
                                                                            );
                                                                            Navigator.pushReplacementNamed(
                                                                              context,
                                                                              '/destinations',
                                                                              arguments: {
                                                                                'tab':
                                                                                    'history',
                                                                              },
                                                                            );
                                                                          },
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: const Color(
                                                                              0xFF7D9240,
                                                                            ),
                                                                            foregroundColor:
                                                                                Colors.white,
                                                                            elevation:
                                                                                0,
                                                                            padding: const EdgeInsets.symmetric(
                                                                              vertical:
                                                                                  12,
                                                                            ),
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                12,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          child: const Text(
                                                                            'View History',
                                                                            style: TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
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
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Finish Trip',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF7D9240,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
