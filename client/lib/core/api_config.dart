
class ApiConfig {
  ApiConfig._();

  // Override at launch if the backend runs on another computer.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const Duration timeout = Duration(seconds: 15);
}
