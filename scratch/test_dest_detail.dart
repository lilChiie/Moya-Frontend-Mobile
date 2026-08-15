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

  // 1. Get all accessibility items
  final accRes = await http.get(Uri.parse('$baseUrl/api/accessibility/'), headers: headers);
  print('ACCESSIBILITY ITEMS: ${accRes.body}');

  // 2. Get destination detail for destination 1, 2, or first from /api/destinations/
  final destsRes = await http.get(Uri.parse('$baseUrl/api/destinations/'), headers: headers);
  print('DESTINATIONS: ${destsRes.body.substring(0, destsRes.body.length.clamp(0, 500))}');

  // Let's decode destinations and get the detail for the first one
  final decoded = jsonDecode(destsRes.body);
  if (decoded['data'] != null && (decoded['data'] as List).isNotEmpty) {
    final firstId = decoded['data'][0]['id'];
    final detailRes = await http.get(Uri.parse('$baseUrl/api/destinations/$firstId'), headers: headers);
    print('DESTINATION $firstId DETAIL: ${detailRes.body}');
  }
}
