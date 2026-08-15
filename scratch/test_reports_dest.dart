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

  // Test 1: GET /api/reports
  final repRes = await http.get(Uri.parse('$baseUrl/api/reports'), headers: headers);
  print('GET /api/reports => ${repRes.statusCode}');
  print(repRes.body.substring(0, repRes.body.length.clamp(0, 1000)));

  // Test 2: GET /api/reports/latest
  final latRes = await http.get(Uri.parse('$baseUrl/api/reports/latest'), headers: headers);
  print('GET /api/reports/latest => ${latRes.statusCode}');
  print(latRes.body.substring(0, latRes.body.length.clamp(0, 1000)));

  // Test 3: Check image URL accessibility
  try {
    final decoded = jsonDecode(repRes.body);
    final data = decoded['data'] is List ? decoded['data'] as List : [];
    if (data.isNotEmpty) {
      final firstReport = data[0];
      print('First report: $firstReport');
      final imgUrl = firstReport['image_url'];
      print('Testing image URL: $imgUrl');
      final imgRes = await http.get(Uri.parse(imgUrl), headers: {'ngrok-skip-browser-warning': 'true'});
      print('Image fetch status: ${imgRes.statusCode}, size: ${imgRes.bodyBytes.length}');
    }
  } catch (e) {
    print('Image test error: $e');
  }

  // Test 4: Check if destination 12 has reports endpoint
  for (var path in ['/api/destinations/12/reports', '/api/reports?destination_id=12', '/api/reports?destination=12']) {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    print('GET $path => ${res.statusCode} | ${res.body.substring(0, res.body.length.clamp(0, 200))}');
  }
}
