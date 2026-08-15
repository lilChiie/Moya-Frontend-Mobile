import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://a439-103-164-80-87.ngrok-free.app';
  const imgPath = '/static/uploads/reports/20260815_232347_488712_scaled_5aad5f42-b06d-411a-9fbf-ac53a533437a5607643093062378979.jpg';
  
  final fullUrl = '$baseUrl$imgPath';
  final res = await http.get(Uri.parse(fullUrl), headers: {'ngrok-skip-browser-warning': 'true'});
  print('Image status: ${res.statusCode}, Content-Type: ${res.headers['content-type']}, Size: ${res.bodyBytes.length} bytes');
}
