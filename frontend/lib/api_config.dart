class ApiConfig {
  // Looks for 'API_URL' passed during build, defaults to localhost if not found
  static const String baseUrl = String.fromEnvironment(
    'WEB_API_URL', 
    defaultValue: 'http://localhost:8000'
  );
}