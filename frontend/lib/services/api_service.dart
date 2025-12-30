import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<http.Response> get(String endpoint) {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/$endpoint');
    return http.get(uri);
  }
}
