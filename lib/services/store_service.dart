import '../config/api_config.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class StoreService {
  final ApiService _api = ApiService();

  // Get Nearby Stores
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final response = await _api.get(
      '${ApiConfig.stores}/nearby?lat=$latitude&lng=$longitude&radius_km=$radiusKm',
    );

    print('Store service received response type: ${response.runtimeType}');

    try {
      // Handle different response formats
      if (response is List) {
        // If response is directly a list
        print('Response is a list with ${response.length} items');
        final List<StoreModel> stores = [];
        
        for (var i = 0; i < response.length; i++) {
          try {
            final storeData = response[i];
            print('Processing store $i: $storeData');
            print('Store data type: ${storeData.runtimeType}');
            
            if (storeData is Map<String, dynamic>) {
              final store = StoreModel.fromJson(storeData);
              stores.add(store);
            } else {
              print('Store data is not a Map<String, dynamic>, it is: ${storeData.runtimeType}');
            }
          } catch (e, stackTrace) {
            print('Error parsing store at index $i: $e');
            print('Stack trace: $stackTrace');
          }
        }
        
        print('Successfully parsed ${stores.length} stores');
        return stores;
      } else if (response is Map && response['stores'] != null && response['stores'] is List) {
        final storesList = response['stores'] as List;
        final List<StoreModel> stores = [];
        
        for (var i = 0; i < storesList.length; i++) {
          try {
            final storeData = storesList[i];
            if (storeData is Map<String, dynamic>) {
              final store = StoreModel.fromJson(storeData);
              stores.add(store);
            }
          } catch (e, stackTrace) {
            print('Error parsing store at index $i: $e');
            print('Stack trace: $stackTrace');
          }
        }
        
        return stores;
      }
    } catch (e, stackTrace) {
      print('Error in getNearbyStores: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
    
    return [];
  }

  // Get Store by ID
  Future<StoreModel> getStoreById(String storeId) async {
    final response = await _api.get('${ApiConfig.stores}/$storeId');
    return StoreModel.fromJson(response);
  }

  // Get Store Products
  Future<List<ProductModel>> getStoreProducts(
    String storeId, {
    String? category,
    int limit = 200,
  }) async {
    String url = '${ApiConfig.products}/stores/$storeId/products?limit=$limit';
    if (category != null) {
      url += '&category=$category';
    }

    final response = await _api.get(url);

    final products = (response['products'] as List)
        .map((product) => ProductModel.fromJson(product))
        .toList();

    return products;
  }

  // Search Products
  Future<List<ProductModel>> searchProducts(
    String storeId,
    String query,
  ) async {
    final response = await _api.get(
      '${ApiConfig.products}/stores/$storeId/search?q=$query',
    );

    final products = (response['results'] as List)
        .map((product) => ProductModel.fromJson(product))
        .toList();

    return products;
  }
}
