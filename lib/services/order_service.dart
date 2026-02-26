import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  // Create Order
  Future<OrderModel> createOrder({
    required String userId,
    required String storeId,
    required List<CartItemModel> items,
    required String fulfillmentType,
    DeliveryAddress? deliveryAddress,
    double appliedDiscount = 0,
    String? sessionId,
  }) async {
    final response = await _api.post(
      ApiConfig.orders,
      {
        'user_id': userId,
        'store_id': storeId,
        'items': items.map((item) => item.toOrderJson()).toList(), // Use toOrderJson for API
        'fulfillment_type': fulfillmentType,
        'delivery_address': deliveryAddress?.toJson(),
        'applied_discount': appliedDiscount,
        'session_id': sessionId,
      },
    );

    return OrderModel.fromJson(response);
  }

  // Get Order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    final response = await _api.get('${ApiConfig.orders}/$orderId');
    return OrderModel.fromJson(response);
  }

  // Get User Orders
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final response = await _api.get('${ApiConfig.orders}?user_id=$userId');
    
    final orders = (response['orders'] as List)
        .map((order) => OrderModel.fromJson(order))
        .toList();

    return orders;
  }

  // Update Order Status
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    await _api.put(
      '${ApiConfig.orders}/$orderId/status',
      {
        'status': status,
        'notes': notes,
      },
    );
  }
}
