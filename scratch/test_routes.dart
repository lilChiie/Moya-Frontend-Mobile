import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc4NjgxMjM1MCwianRpIjoiYWE4MTQyZGEtY2I5Ni00YTRiLWE4NDYtZDUyOTdjMTBmMWFiIiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjMiLCJuYmYiOjE3ODY4MTIzNTAsImNzcmYiOiI4NTRjM2M2Ny1lMmJlLTRkYmEtYjZmMS1hNTE3NGY4Y2Q4Y2MiLCJleHAiOjE3ODc0MTcxNTB9._mSpPfV1yq-UTTIwpvVO51CJiVZ_iKvYXe9b2SM-KC0';

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Authorization': 'Bearer $token',
  };

  // Test GET and POST on /api/routes and /api/recommendation
  for (var path in ['/api/routes', '/api/routes/', '/api/recommendation']) {
    final url = Uri.parse('$baseUrl$path');
    try {
      final getRes = await http.get(url, headers: headers);
      print('GET $path => ${getRes.statusCode} | ${getRes.body.substring(0, getRes.body.length.clamp(0, 300))}');
    } catch (e) {
      print('GET $path error => $e');
    }

    try {
      final postRes = await http.post(url, headers: headers, body: jsonEncode({
        'user_id': 3,
        'accessibility_ids': [3],
        'tourism_id': [3],
        'duration_minutes': 180,
        'max_distance_km': 50,
        'budget': 500000,
      }));
      print('POST $path => ${postRes.statusCode} | ${postRes.body.substring(0, postRes.body.length.clamp(0, 300))}');
    } catch (e) {
      print('POST $path error => $e');
    }
  }
}
