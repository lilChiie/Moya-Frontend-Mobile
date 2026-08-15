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

  final keysToTest = [
    'accessibility',
    'accessibility_id',
    'accessibility_need_id',
    'accessibility_needs_id',
    'access_id',
    'access_ids',
    'accessibility_type',
    'accessibility_type_id',
    'accessibility_category_id',
  ];

  for (var key in keysToTest) {
    final payload = {
      "user_id": 3,
      "accessibility_ids": [8],
      "tourism_id": 3,
      "budget": 150000,
      "duration_minutes": 480,
      "max_distance_km": 50,
      "latitude": 1.136,
      "longitude": 104.029,
      key: 8,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/recommendation'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (!res.body.contains("Column 'accessibility_id' cannot be null")) {
      print('>>> SUCCESS/DIFFERENT with key $key! Status: ${res.statusCode} | Body: ${res.body}');
      return;
    } else {
      print('Key $key still yielded None');
    }
  }

  // Also test if all keys sent at once
  final allPayload = {
    "user_id": 3,
    "accessibility_ids": [8],
    "tourism_id": 3,
    "budget": 150000,
    "duration_minutes": 480,
    "max_distance_km": 50,
    "latitude": 1.136,
    "longitude": 104.029,
  };
  for (var key in keysToTest) {
    allPayload[key] = 8;
  }
  final resAll = await http.post(
    Uri.parse('$baseUrl/api/recommendation'),
    headers: headers,
    body: jsonEncode(allPayload),
  );
  print('All keys at once: ${resAll.body}');
}
