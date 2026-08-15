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
  final url = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/tourism/latest');
  
  final response = await http.get(
    url,
    headers: {
       'Authorization': 'Bearer $token',
       'ngrok-skip-browser-warning': 'true'
    }
  );
  print("Status: ${response.statusCode}");
  print("Body: ${response.body}");
}
