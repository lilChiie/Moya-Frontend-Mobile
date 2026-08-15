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

  final variations = [
    // Variation 1: tourism_id as int
    {
      'user_id': 3,
      'accessibility_ids': [3],
      'tourism_id': 3,
      'duration_minutes': 180,
      'max_distance_km': 50,
      'budget': 500000,
    },
    // Variation 2: tourism_id as list
    {
      'user_id': 3,
      'accessibility_ids': [3],
      'tourism_id': [3],
      'duration_minutes': 180,
      'max_distance_km': 50.0,
      'budget': 500000.0,
    },
    // Variation 3: accessibility_id as int
    {
      'user_id': 3,
      'accessibility_ids': [3],
      'tourism_id': 3,
      'duration_minutes': 180,
      'max_distance_km': 50.0,
      'budget': 500000,
    },
    // Variation 4: with lat/lon
    {
      'user_id': 3,
      'accessibility_ids': [3],
      'tourism_id': 3,
      'duration_minutes': 180,
      'max_distance_km': 50,
      'budget': 500000,
      'latitude': 1.136,
      'longitude': 104.029,
    },
    // Variation 5: user_location
    {
      'user_id': 3,
      'accessibility_ids': [3],
      'tourism_id': 3,
      'duration_minutes': 180,
      'max_distance_km': 50,
      'budget': 500000,
      'current_lat': 1.136,
      'current_lng': 104.029,
    },
  ];

  for (var i = 0; i < variations.length; i++) {
    final url = Uri.parse('$baseUrl/api/recommendation');
    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode(variations[i]),
    );
    print('Var $i => ${res.statusCode} | ${res.body.substring(0, res.body.length.clamp(0, 300))}');
  }
}
