class ApiConfig {
  // Base URL - Production (Render)
   //static const String baseUrl = 'https://nukkadmartbackend.onrender.com';
  
  static const String baseUrl = 'http://10.174.65.38:8000'; // Physical Device (Updated IP)
  
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';
  
  // Endpoints
  static const String stores = '$apiBaseUrl/stores';
  static const String products = '$apiBaseUrl/inventory';
  static const String users = '$apiBaseUrl/users';
  static const String orders = '$apiBaseUrl/orders';
  static const String payments = '$apiBaseUrl/payments';
  static const String nudge = '$apiBaseUrl/nudge';
  static const String ocr = '$apiBaseUrl/ocr';
  
  // WebSocket - Production
  // static const String wsBaseUrl = 'wss://nukkadmartbackend.onrender.com$apiVersion';
  
  // WebSocket - Local testing
  // static const String wsBaseUrl = 'ws://10.0.2.2:8000$apiVersion'; // Defaulting to Android emulator
  // static const String wsBaseUrl = 'ws://127.0.0.1:8000$apiVersion'; // iOS Simulator
  static const String wsBaseUrl = 'ws://10.174.65.38:8000$apiVersion'; // Physical Device (Updated IP)
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyCsZ1wSI0CdaLU35oH4l4dhQrz7TjBSYTw';
  
  // Razorpay Keys
  static const String razorpayKeyId = 'rzp_live_IOk2tHMSQHhGzI';
  
  // Default Location (Bhopal)
  static const double defaultLatitude = 23.2599;
  static const double defaultLongitude = 77.4126;
}
