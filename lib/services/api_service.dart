import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: _headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST Request
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT Request
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse(endpoint),
            headers: _headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle Response
  dynamic _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        final decoded = jsonDecode(response.body);
        print('Decoded response type: ${decoded.runtimeType}');
        if (decoded is List) {
          print('Response is a list with ${decoded.length} items');
          if (decoded.isNotEmpty) {
            print('First item type: ${decoded[0].runtimeType}');
            print('First item: ${decoded[0]}');
          }
        } else if (decoded is Map) {
          print('Response is a map with keys: ${decoded.keys}');
        }
        return decoded;
      } catch (e, stackTrace) {
        print('Error decoding JSON: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }
}
