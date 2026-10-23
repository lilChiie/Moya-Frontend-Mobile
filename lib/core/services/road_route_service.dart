import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRouteResult {
  final List<LatLng> coordinates;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final bool isActualRoad;
  final String? errorMessage;

  const RoadRouteResult({
    required this.coordinates,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    this.isActualRoad = true,
    this.errorMessage,
  });

  double get distanceKm => totalDistanceMeters / 1000.0;

  String get formattedDistance {
    if (totalDistanceMeters <= 0) return '0 m';
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000.0).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.toStringAsFixed(0)} m';
  }

  int get durationMinutes => (totalDurationSeconds / 60.0).round();

  String get formattedDuration {
    final mins = durationMinutes;
    if (mins <= 0) return '0 min';
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
}

class RoadRouteService {
  static final RoadRouteService _instance = RoadRouteService._internal();
  factory RoadRouteService() => _instance;
  RoadRouteService._internal();

  final Map<String, RoadRouteResult> _cache = {};

  /// Fetches actual road network route using OSRM Driving API.
  /// Given waypoints, it returns detailed polylines that follow real roads.
  /// Falls back smoothly to straight line segments if network or server fails.
  Future<RoadRouteResult> getRoadRoute(List<LatLng> waypoints) async {
    if (waypoints.isEmpty) {
      return const RoadRouteResult(
        coordinates: [],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        isActualRoad: true,
      );
    }

    if (waypoints.length == 1) {
      return RoadRouteResult(
        coordinates: [waypoints.first],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        isActualRoad: true,
      );
    }

    // Generate cache key from waypoints
    final cacheKey = waypoints
        .map(
          (p) =>
              '${p.longitude.toStringAsFixed(5)},${p.latitude.toStringAsFixed(5)}',
        )
        .join(';');

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // OSRM coordinates format: {lon1},{lat1};{lon2},{lat2};...
      final coordsParam = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson',
      );

      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'MoyaMobileApp/1.0 (Accessible Tourism Platform)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map &&
            data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          if (geometry is Map && geometry['coordinates'] is List) {
            final rawCoords = geometry['coordinates'] as List;
            final List<LatLng> roadPoints = [];

            for (var c in rawCoords) {
              if (c is List && c.length >= 2) {
                final lng = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                roadPoints.add(LatLng(lat, lng));
              }
            }

            final totalDistance =
                (route['distance'] as num?)?.toDouble() ?? 0.0;
            final totalDuration =
                (route['duration'] as num?)?.toDouble() ?? 0.0;

            final result = RoadRouteResult(
              coordinates: roadPoints,
              totalDistanceMeters: totalDistance,
              totalDurationSeconds: totalDuration,
              isActualRoad: true,
            );

            _cache[cacheKey] = result;
            return result;
          }
        }
      }
    } catch (_) {
      // Fallback gracefully on timeout or network error
    }

    // Fallback: Return straight-line waypoints with approximate distance
    final fallbackDistance = _calculateStraightLineDistance(waypoints);
    final fallbackResult = RoadRouteResult(
      coordinates: waypoints,
      totalDistanceMeters: fallbackDistance,
      totalDurationSeconds: 0,
      isActualRoad: false,
    );

    return fallbackResult;
  }

  double _calculateStraightLineDistance(List<LatLng> points) {
    const distanceCalculator = Distance();
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceCalculator.as(
        LengthUnit.Meter,
        points[i],
        points[i + 1],
      );
    }
    return total;
  }

  void clearCache() {
    _cache.clear();
  }
}
