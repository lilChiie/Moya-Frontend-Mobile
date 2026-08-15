import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class RouteService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// POST /api/recommendation
  /// Generates optimized route based on user preferences and constraints
  Future<Map<String, dynamic>> getRouteRecommendation({
    int? userId,
    required List<int> accessibilityIds,
    required int tourismId,
    required double budget,
    required int durationMinutes,
    required double maxDistanceKm,
    double? latitude,
    double? longitude,
  }) async {
    final token = await _getToken();
    final storedUserId = await _getUserId();
    final effectiveUserId = userId ?? storedUserId ?? 1;

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recommendation}');
    
    final payload = {
      'user_id': effectiveUserId,
      'accessibility_id': accessibilityIds.isNotEmpty ? accessibilityIds.first : null,
      'accessibility_ids': accessibilityIds,
      'tourism_id': tourismId,
      'budget': budget,
      'duration_minutes': durationMinutes,
      'max_distance_km': maxDistanceKm,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Route generated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['msg'] ?? responseData['error'] ?? 'Failed to generate route.',
          'data': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong: $e',
      };
    }
  }

  /// GET /api/routes
  /// Fetch user route histories / saved routes
  Future<Map<String, dynamic>> getRoutes() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routes}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> list = [];
        if (responseData is Map && responseData.containsKey('data')) {
          list = responseData['data'] as List<dynamic>? ?? [];
        } else if (responseData is List) {
          list = responseData;
        }

        return {
          'success': true,
          'data': list,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load routes.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong: $e',
      };
    }
  }
}

class TripRouteManager {
  static final TripRouteManager _instance = TripRouteManager._internal();
  factory TripRouteManager() => _instance;
  TripRouteManager._internal();

  final List<Map<String, dynamic>> _userRoute = [];

  List<Map<String, dynamic>> get userRoute => List.unmodifiable(_userRoute);

  bool addDestination(Map<String, dynamic> dest) {
    final title = (dest['title'] ?? dest['name'] ?? 'Destination').toString();
    final id = dest['id'];

    // Check if already in the list
    final exists = _userRoute.any((d) => (id != null && d['id'] == id) || d['title'] == title);
    if (!exists) {
      final double lat = double.tryParse(dest['lat']?.toString() ?? dest['latitude']?.toString() ?? '1.1293') ?? 1.1293;
      final double lng = double.tryParse(dest['lng']?.toString() ?? dest['longitude']?.toString() ?? '104.0538') ?? 104.0538;
      final dynamic duration = dest['estimated_duration'] ?? dest['duration'] ?? 90;
      final int fee = (num.tryParse((dest['entrance_fee'] ?? dest['fee'] ?? 0).toString()) ?? 0).toInt();

      _userRoute.add({
        'id': id,
        'title': title,
        'time': '$duration mins',
        'lat': lat != 0.0 ? lat : 1.1293,
        'lng': lng != 0.0 ? lng : 104.0538,
        'fee': fee,
        'image': dest['image_url'] ?? dest['image'],
      });
      return true;
    }
    return false;
  }

  void removeDestination(int index) {
    if (index >= 0 && index < _userRoute.length) {
      _userRoute.removeAt(index);
    }
  }

  void clearRoute() {
    _userRoute.clear();
  }
}

class DestinationHistoryManager {
  static final DestinationHistoryManager _instance = DestinationHistoryManager._internal();
  factory DestinationHistoryManager() => _instance;
  DestinationHistoryManager._internal();

  static const String _key = 'destination_history_list';

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addDestinations(List<Map<String, dynamic>> destinations) async {
    if (destinations.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();

    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (var dest in destinations) {
      final title = (dest['title'] ?? dest['name'] ?? 'Destinasi').toString();
      final id = dest['id'];

      // Avoid immediate consecutive duplicates if already added at the very top
      current.insert(0, {
        'id': id,
        'title': title,
        'name': title,
        'category': dest['category'] ?? 'Inclusive Tourism',
        'image_url': dest['image_url'] ?? dest['image'],
        'image': dest['image'] ?? dest['image_url'],
        'latitude': dest['latitude'] ?? dest['lat'],
        'longitude': dest['longitude'] ?? dest['lng'],
        'entrance_fee': dest['entrance_fee'] ?? dest['fee'] ?? 0,
        'estimated_duration': dest['estimated_duration'] ?? dest['time'] ?? '60 min',
        'visited_at': dateStr,
        'status': 'Completed',
      });
    }

    await prefs.setString(_key, jsonEncode(current));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  String _getMonthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }
}

class SavedRouteManager {
  static final SavedRouteManager _instance = SavedRouteManager._internal();
  factory SavedRouteManager() => _instance;
  SavedRouteManager._internal();

  static const String _key = 'saved_routes_list';

  Future<List<Map<String, dynamic>>> getSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCurrentRoute({
    String? title,
    required List<Map<String, dynamic>> destinations,
    required String totalDuration,
    required String totalCost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedRoutes();

    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';

    current.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': (title != null && title.trim().isNotEmpty) ? title : 'Batam Trip ${now.day}/${now.month}',
      'date': dateStr,
      'destinations_count': destinations.length,
      'total_duration': totalDuration,
      'total_cost': totalCost,
      'destinations': destinations,
    });

    await prefs.setString(_key, jsonEncode(current));
  }

  String _getMonthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }
}


