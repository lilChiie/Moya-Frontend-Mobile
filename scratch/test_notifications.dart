import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc4Njc5MzYyMywianRpIjoiOTVlOTUxZTEtZjNmOS00Yzk4LTgwNDEtMmY4NWU3OGM3MjYxIiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjQiLCJuYmYiOjE3ODY3OTM2MjMsImNzcmYiOiI1ZGJkYTljNi04NjVlLTRiNTItYmQ4My1jZmZlYmNmMjg1MmMiLCJleHAiOjE3ODczOTg0MjN9.b3uee8qLEveicTqUH39YthhEW9r5uiQM9g_cx_YGWZQ';
  
  for (var path in ['/api/notifications', '/api/notifications/', '/api/notifications/1/read']) {
    final url = Uri.parse('$baseUrl$path');
    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Bearer $token',
    });
    print('GET $path => ${res.statusCode} | ${res.body.substring(0, res.body.length.clamp(0, 300))}');
  }

  // Test PUT read
  final putUrl = Uri.parse('$baseUrl/api/notifications/1/read');
  final putRes = await http.put(putUrl, headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Authorization': 'Bearer $token',
  }, body: '');
  print('\nPUT /api/notifications/1/read => ${putRes.statusCode} | ${putRes.body}');
}
