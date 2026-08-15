import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://a439-103-164-80-87.ngrok-free.app/api/reports');
  var response = await http.get(url, headers: {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  });
  if (response.statusCode == 200) {
    var json = jsonDecode(response.body);
    if (json.containsKey('data') && (json['data'] as List).isNotEmpty) {
      print('First item: ${jsonEncode(json['data'][0])}');
    }
  }
}
