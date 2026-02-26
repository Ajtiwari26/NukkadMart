import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Quick Register (Name + Phone)
  Future<UserModel> quickRegister(String name, String phone) async {
    final response = await _api.post(
      '${ApiConfig.users}/quick-register',
      {
        'name': name,
        'phone': phone,
      },
    );

    return UserModel.fromJson(response);
  }

  // Get User by ID
  Future<UserModel> getUserById(String userId) async {
    final response = await _api.get('${ApiConfig.users}/$userId');
    return UserModel.fromJson(response);
  }

  // Update Profile
  Future<void> updateProfile(String userId, {String? name, String? email}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;

    await _api.put('${ApiConfig.users}/profile?user_id=$userId', data);
  }

  // Save Address (Mocked Backend Call)
  Future<AddressModel> saveAddress(String userId, Map<String, dynamic> addressData) async {
    // START: Mocking backend response
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate returning data
    
    // In a real app, you would POST to /users/$userId/addresses
    // final response = await _api.post('${ApiConfig.users}/$userId/addresses', addressData);
    // return AddressModel.fromJson(response);

    // Returning local mock for now
    return AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: addressData['label'],
      house: addressData['house'],
      apartment: addressData['apartment'],
      landmark: addressData['landmark'],
      lat: addressData['lat'],
      lng: addressData['lng'],
      isDefault: true, // Always make the new one default/preferred for now
    );
    // END: Mock
  }
}
