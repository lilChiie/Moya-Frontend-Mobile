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

  // 1. Check GET /api/routes
  final res1 = await http.get(Uri.parse('$baseUrl/api/routes'), headers: headers);
  print('GET /api/routes: ${res1.statusCode} | ${res1.body}');

  // 2. Check POST /api/routes
  final res2 = await http.post(
    Uri.parse('$baseUrl/api/routes'),
    headers: headers,
    body: jsonEncode({
      'name': 'Trip Batam Hari Ini',
      'destinations': [12, 13],
      'total_duration': '120',
      'total_cost': '15000',
    }),
  );
  print('POST /api/routes: ${res2.statusCode} | ${res2.body}');
}
