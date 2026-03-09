class ApiConfig {
  // ============================================
  // BASE URL CONFIGURATION
  // Uncomment the one you need, comment others
  // ============================================
  
  // Local Development (for web testing)
  // static const String baseUrl = 'http://localhost:8000';
  
  // Production - AWS EC2 (domain with HTTPS)
  static const String baseUrl = 'https://api.nukkadfoods.com';
  
  // Production - Render
  // static const String baseUrl = 'https://nukkadmartbackend.onrender.com';
  
  // Physical Device (Local Network - Update IP as needed)
  // static const String baseUrl = 'http://10.174.65.38:8000';
  
  // ============================================
  
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
  
  // ============================================
  // WEBSOCKET URL CONFIGURATION
  // Must match the baseUrl above
  // ============================================
  
  // Local Development
  // static const String wsBaseUrl = 'ws://localhost:8000$apiVersion';
  
  // Production - AWS EC2
  static const String wsBaseUrl = 'wss://api.nukkadfoods.com$apiVersion';
  
  // Physical Device (Local Network)
  // static const String wsBaseUrl = 'ws://10.174.65.38:8000$apiVersion';
  
  // ============================================
  
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