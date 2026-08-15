import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc4NjgxMjM1MCwianRpIjoiYWE4MTQyZGEtY2I5Ni00YTRiLWE4NDYtZDUyOTdjMTBmMWFiIiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjMiLCJuYmYiOjE3ODY4MTIzNTAsImNzcmYiOiI4NTRjM2M2Ny1lMmJlLTRkYmEtYjZmMS1hNTE3NGY4Y2Q4Y2MiLCJleHAiOjE3ODc0MTcxNTB9._mSpPfV1yq-UTTIwpvVO51CJiVZ_iKvYXe9b2SM-KC0';

  // Let's get destinations list first
  final listUrl = Uri.parse('$baseUrl/api/destinations/');
  final listRes = await http.get(listUrl, headers: {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Authorization': 'Bearer $token',
  });
  print('GET /api/destinations/ status: ${listRes.statusCode}');
  print('GET /api/destinations/ body: ${listRes.body.substring(0, listRes.body.length.clamp(0, 500))}');

  // Let's test a destination detail (e.g. id 1, 12, etc.)
  for (var id in [1, 2, 12, 13]) {
    final destUrl = Uri.parse('$baseUrl/api/destinations/$id');
    final destRes = await http.get(destUrl, headers: {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Bearer $token',
    });
    print('GET /api/destinations/$id status: ${destRes.statusCode}');
    if (destRes.statusCode == 200) {
      print('GET /api/destinations/$id body: ${destRes.body}');
    }
  }
}
