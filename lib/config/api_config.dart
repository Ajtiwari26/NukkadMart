class ApiConfig {
  // Base URL - Change this to your backend URL
  // For physical device: Use your computer's IP address
  // For Android emulator: Use http://10.0.2.2:8000
  // For iOS simulator: Use http://localhost:8000
  
  // LOCAL DEVELOPMENT - Backend running on your machine
  //static const String baseUrl = 'http://10.233.137.38:8000';
  
  // PRODUCTION - Uncomment when deploying
   static const String baseUrl = 'https://nukkad-mart-backend.vercel.app';
  
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
  
  // WebSocket
  static const String wsBaseUrl = 'ws://10.233.137.38:8000$apiVersion';
  
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
