# NukkadMart Flutter App

A Flutter mobile application for NukkadMart - Your Local Grocery Store.

## Features

- 🔐 User Authentication (Quick Register with Name + Phone)
- 🏪 Browse Nearby Stores
- 🛒 Shopping Cart Management
- 📦 Order Placement & Tracking
- 💳 Razorpay Payment Integration
- 📍 Location-based Store Discovery
- 👤 User Profile & Order History
- 🔔 Real-time Order Updates (WebSocket)

## Project Structure

```
flutterapp/
├── lib/
│   ├── config/
│   │   └── api_config.dart          # API endpoints and configuration
│   ├── models/
│   │   ├── user_model.dart          # User data model
│   │   ├── store_model.dart         # Store data model
│   │   ├── product_model.dart       # Product data model
│   │   ├── cart_item_model.dart     # Cart item model
│   │   └── order_model.dart         # Order data model
│   ├── providers/
│   │   ├── auth_provider.dart       # Authentication state management
│   │   ├── cart_provider.dart       # Cart state management
│   │   ├── store_provider.dart      # Store state management
│   │   └── order_provider.dart      # Order state management
│   ├── services/
│   │   ├── api_service.dart         # Base API service
│   │   ├── auth_service.dart        # Authentication API calls
│   │   ├── store_service.dart       # Store API calls
│   │   └── order_service.dart       # Order API calls
│   ├── screens/
│   │   ├── splash_screen.dart       # Splash/Loading screen
│   │   ├── login_screen.dart        # Login/Register screen
│   │   ├── home_screen.dart         # Home screen with store list
│   │   ├── store_screen.dart        # Store details & products
│   │   ├── cart_screen.dart         # Shopping cart
│   │   ├── checkout_screen.dart     # Checkout & payment
│   │   ├── profile_screen.dart      # User profile
│   │   └── order_tracking_screen.dart # Order tracking
│   ├── utils/
│   │   └── app_colors.dart          # App color constants
│   └── main.dart                    # App entry point
├── assets/
│   ├── images/                      # Image assets
│   └── icons/                       # Icon assets
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

## Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android Studio** or **Xcode** (for iOS)

3. **Backend Running**
   - Ensure your NukkadMart backend is running on `http://localhost:8000`
   - Or update the `baseUrl` in `lib/config/api_config.dart`

### Installation

1. **Navigate to the Flutter app directory**
   ```bash
   cd flutterapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API Configuration**
   
   Edit `lib/config/api_config.dart` and update the base URL:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000'; // For physical device
   // or
   static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
   ```

4. **Configure Android Permissions**
   
   The app requires location permissions. These are already configured in the template, but verify:
   
   `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```

5. **Configure iOS Permissions**
   
   `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to find nearby stores</string>
   ```

6. **Add Google Maps API Key**
   
   - Get your API key from Google Cloud Console
   - Update `lib/config/api_config.dart`:
     ```dart
     static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
     ```

### Running the App

1. **Check connected devices**
   ```bash
   flutter devices
   ```

2. **Run on Android**
   ```bash
   flutter run
   ```

3. **Run on iOS**
   ```bash
   flutter run -d ios
   ```

4. **Run in debug mode**
   ```bash
   flutter run --debug
   ```

5. **Build APK (Android)**
   ```bash
   flutter build apk --release
   ```

6. **Build iOS**
   ```bash
   flutter build ios --release
   ```

## Backend API Endpoints

The app connects to these backend endpoints:

- `POST /api/v1/users/quick-register` - User registration
- `GET /api/v1/users/{user_id}` - Get user data
- `GET /api/v1/stores/nearby` - Get nearby stores
- `GET /api/v1/stores/{store_id}` - Get store details
- `GET /api/v1/inventory/stores/{store_id}/products` - Get store products
- `POST /api/v1/orders` - Create order
- `GET /api/v1/orders?user_id={user_id}` - Get user orders
- `POST /api/v1/payments/create-order` - Create Razorpay order
- `POST /api/v1/payments/verify` - Verify payment

## State Management

The app uses **Provider** for state management with the following providers:

- **AuthProvider**: Manages user authentication state
- **CartProvider**: Manages shopping cart
- **StoreProvider**: Manages store and product data
- **OrderProvider**: Manages order data

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1              # State management
  http: ^1.2.0                  # HTTP requests
  shared_preferences: ^2.2.2    # Local storage
  google_maps_flutter: ^2.5.3   # Maps integration
  geolocator: ^11.0.0           # Location services
  razorpay_flutter: ^1.3.6      # Payment gateway
  google_fonts: ^6.1.0          # Custom fonts
  cached_network_image: ^3.3.1  # Image caching
```

## Development Workflow

### Adding a New Screen

1. Create screen file in `lib/screens/`
2. Add route in `lib/main.dart`
3. Implement UI based on design
4. Connect to providers for data

### Adding a New API Endpoint

1. Add endpoint to `lib/config/api_config.dart`
2. Create/update service in `lib/services/`
3. Update provider if needed
4. Use in screens

### Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Troubleshooting

### Common Issues

1. **Cannot connect to backend**
   - Check if backend is running
   - Update `baseUrl` in `api_config.dart`
   - For Android emulator, use `10.0.2.2` instead of `localhost`
   - For physical device, use your computer's IP address

2. **Location permission denied**
   - Grant location permission in device settings
   - App will use default location (Bhopal) as fallback

3. **Build errors**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Gradle build failed (Android)**
   - Update Android SDK
   - Check `android/build.gradle` for correct versions

## Next Steps

### Screens to Implement

Based on your designs, implement these screens:

1. **Store Screen** (`store_screen.dart`)
   - Display store details
   - Show product list with categories
   - Add to cart functionality
   - Search products

2. **Cart Screen** (`cart_screen.dart`)
   - Show cart items
   - Update quantities
   - Apply discounts
   - Proceed to checkout

3. **Checkout Screen** (`checkout_screen.dart`)
   - Delivery address form
   - Payment method selection
   - Razorpay integration
   - Order confirmation

4. **Profile Screen** (`profile_screen.dart`)
   - User information
   - Order history
   - Logout option

5. **Order Tracking Screen** (`order_tracking_screen.dart`)
   - Order status timeline
   - Real-time updates via WebSocket
   - Order details

### Features to Add

- [ ] Image upload for OCR (shopping list)
- [ ] Push notifications
- [ ] Offline mode with local caching
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Product search and filters
- [ ] Favorites/Wishlist
- [ ] Ratings and reviews

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

Proprietary - NukkadMart

## Support

For issues or questions, contact the development team.
