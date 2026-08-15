import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginUrl = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/auth/login');
  final loginRes = await http.post(
    loginUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'nofira1@gmail.com', 'password': '12345'}),
  );
  
  final token = jsonDecode(loginRes.body)['access_token'];
  
  final url1 = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/history/');
  final res1 = await http.get(url1, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'});
  print("Status /api/history/: ${res1.statusCode}");
  print("Body /api/history/: ${res1.body}");

  final url2 = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/destinations/history/');
  final res2 = await http.get(url2, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'});
  print("Status /api/destinations/history/: ${res2.statusCode}");
}
