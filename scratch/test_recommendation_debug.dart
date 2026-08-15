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

  final tests = [
    // 1. User's exact curl
    {
      "user_id": 1,
      "accessibility_ids": [8, 9],
      "tourism_id": 3,
      "budget": 150000,
      "duration_minutes": 480,
      "max_distance_km": 50,
      "latitude": 1.136,
      "longitude": 104.029
    },
    // 2. With accessibility_id as int
    {
      "user_id": 3,
      "accessibility_id": 8,
      "accessibility_ids": [8],
      "tourism_id": 3,
      "budget": 150000,
      "duration_minutes": 480,
      "max_distance_km": 50,
      "latitude": 1.136,
      "longitude": 104.029
    },
    // 3. With accessibility_ids: [3]
    {
      "user_id": 3,
      "accessibility_ids": [3],
      "tourism_id": 3,
      "budget": 150000,
      "duration_minutes": 480,
      "max_distance_km": 50,
      "latitude": 1.136,
      "longitude": 104.029
    },
  ];

  for (var i = 0; i < tests.length; i++) {
    print('\n--- TESTING CASE $i ---');
    final res = await http.post(
      Uri.parse('$baseUrl/api/recommendation'),
      headers: headers,
      body: jsonEncode(tests[i]),
    );
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  }
}
