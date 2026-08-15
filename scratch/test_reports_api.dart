import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urls = [
    'https://a439-103-164-80-87.ngrok-free.app/api/reports',
    'https://a439-103-164-80-87.ngrok-free.app/api/report',
    'https://a439-103-164-80-87.ngrok-free.app/api/report/',
  ];
  
  for (var u in urls) {
    final url = Uri.parse(u);
  try {
    var request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = '3';
    request.fields['destination_id'] = '1';
    request.fields['user_notes'] = 'Some notes here';
    request.files.add(http.MultipartFile.fromBytes('image', [0, 1, 2], filename: 'test.png'));
    request.headers.addAll({
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    });
    
    // Empty request to trigger validation errors
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    
    print('Status: ${response.statusCode}');
    print('Body: $responseBody');
  } catch (e) {
    print('Error: $e');
  }
  }
}
