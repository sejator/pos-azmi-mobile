import 'package:flutter/material.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/models/cart_item.dart';
import 'package:pos_azmi/models/promotion_model.dart';
import 'package:pos_azmi/core/api_client.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  int get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addToCart(CartItem item) {
    final index = _items.indexWhere((e) =>
        e.productId == item.productId &&
        e.variantId == item.variantId &&
        (e.note ?? '').trim() == (item.note ?? '').trim() &&
        e.isBonus == item.isBonus);

    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  void updateQuantity({
    required int productId,
    int? variantId,
    String? note,
    required int quantity,
  }) {
    final index = _items.indexWhere((item) =>
        item.productId == productId &&
        item.variantId == variantId &&
        (item.note ?? '') == (note ?? '') &&
        item.isBonus == false);

    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void removeFromCart(int productId, {int? variantId, String? note}) {
    _items.removeWhere((item) =>
        item.productId == productId &&
        item.variantId == variantId &&
        (item.note ?? '') == (note ?? '') &&
        item.isBonus == false);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toJsonList() {
    return _items.map((item) => item.toJson()).toList();
  }

  void loadFromJsonList(List<Map<String, dynamic>> jsonList) {
    _items
      ..clear()
      ..addAll(jsonList.map((json) => CartItem.fromJson(json)));
    notifyListeners();
  }

  Future<void> checkAndApplyPromotions() async {
    try {
      final outlet = await Storage.getOutlet();
      final res =
          await ApiClient.dio.get('/promotions/active', queryParameters: {
        'outlet_id': outlet?.id,
      });
      final List data = res.data['data'];
      final promos = data.map((e) => Promotion.fromJson(e)).toList();

      _items.removeWhere((item) => item.isBonus);

      for (final promo in promos) {
        final isEligible = promo.conditions.every((cond) {
          return _items.any((item) =>
              item.productId == cond.productId &&
              (cond.variantId == null || item.variantId == cond.variantId) &&
              item.quantity >= cond.qtyRequired);
        });

        if (isEligible) {
          for (final reward in promo.rewards) {
            final alreadyExists = _items.any((item) =>
                item.productId == reward.productId &&
                item.variantId == reward.variantId &&
                item.isBonus);

            if (!alreadyExists) {
              _items.add(CartItem(
                productId: reward.productId,
                productName:
                    _getProductNameById(reward.productId, reward.variantId) ??
                        'Bonus Promo',
                productPrice: 0,
                quantity: reward.qtyRewarded,
                variantId: reward.variantId,
                variantName: null,
                isBonus: true,
                note: 'Bonus dari promo: ${promo.name}',
              ));
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      // Optionally log error or handle gracefully
    }
  }

  String? _getProductNameById(int productId, int? variantId) {
    try {
      final item = _items.firstWhere(
          (item) => item.productId == productId && item.variantId == variantId);
      return item.variantName != null
          ? '${item.productName} (${item.variantName})'
          : item.productName;
    } catch (_) {
      return null;
    }
  }
}
