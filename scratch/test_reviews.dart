import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  
  // Try GET destination detail with a fresh token approach - use the reviews endpoint
  // First try to get destination 12 without token
  final urls = [
    '/api/destinations/12',
    '/api/destinations/12/',
  ];
  
  for (var path in urls) {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    });
    print('GET $path => ${response.statusCode}');
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if (json is Map) {
        print('  Top keys: ${json.keys.toList()}');
        if (json.containsKey('data')) {
          var data = json['data'];
          if (data is Map) {
            print('  data keys: ${data.keys.toList()}');
            if (data.containsKey('reviews')) {
              var reviews = data['reviews'] as List;
              print('  reviews count: ${reviews.length}');
              if (reviews.isNotEmpty) {
                print('  first review keys: ${(reviews[0] as Map).keys.toList()}');
                print('  first review: ${jsonEncode(reviews[0])}');
              }
            }
          }
        }
      }
    } else {
      print('  Body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
    }
  }
}
