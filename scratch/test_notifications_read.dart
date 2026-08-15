import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc4Njc5MzYyMywianRpIjoiOTVlOTUxZTEtZjNmOS00Yzk4LTgwNDEtMmY4NWU3OGM3MjYxIiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjQiLCJuYmYiOjE3ODY3OTM2MjMsImNzcmYiOiI1ZGJkYTljNi04NjVlLTRiNTItYmQ4My1jZmZlYmNmMjg1MmMiLCJleHAiOjE3ODczOTg0MjN9.b3uee8qLEveicTqUH39YthhEW9r5uiQM9g_cx_YGWZQ';
  
  final readPaths = [
    '/api/notifications/1/read',
    '/api/notifications/1/read/',
    '/api/notifications/read/1',
    '/api/notifications/read/1/',
    '/api/notifications/1',
    '/api/notifications/1/',
    '/api/notifications/mark-as-read/1',
    '/api/notifications/1/mark-as-read',
    '/api/notifications/read-all',
    '/api/notifications/read-all/',
  ];

  for (var path in readPaths) {
    for (var method in ['PUT', 'POST', 'PATCH']) {
      final url = Uri.parse('$baseUrl$path');
      http.Response res;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };
      if (method == 'PUT') {
        res = await http.put(url, headers: headers, body: '');
      } else if (method == 'POST') {
        res = await http.post(url, headers: headers, body: '');
      } else {
        res = await http.patch(url, headers: headers, body: '');
      }
      if (res.statusCode != 404 && res.statusCode != 405) {
        print('SUCCESS: $method $path => ${res.statusCode} | ${res.body}');
      }
    }
  }
}
