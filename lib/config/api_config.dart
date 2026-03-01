class ApiConfig {
  // Base URL - Production (Render)
  static const String baseUrl = 'https://nukkadmartbackend.onrender.com';
  
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
  static const String wsBaseUrl = 'wss://nukkadmartbackend.onrender.com$apiVersion';
  
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
