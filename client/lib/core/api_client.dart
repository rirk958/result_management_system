
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../services/auth_service.dart';

class ApiClient {
  ApiClient._();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authService.token != null)
      'Authorization': 'Bearer ${authService.token}',
  };

  static Future<http.Response> get(String path) {
    return http
        .get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    )
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
      }) {
    return http
        .post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    )
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> put(
      String path, {
        Map<String, dynamic>? body,
      }) {
    return http
        .put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    )
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> delete(String path) {
    return http
        .delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    )
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> patch(
      String path, {
        Map<String, dynamic>? body,
      }) {
    return http
        .patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    )
        .timeout(ApiConfig.timeout);
  }
}
