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
  final profileUrl = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/profile/');
  
  final profilePutRes = await http.put(
    profileUrl,
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({'name': 'Nofira cans', 'password': '12345'})
  );
  print("PUT Profile: ${profilePutRes.statusCode} - ${profilePutRes.body}");
}
