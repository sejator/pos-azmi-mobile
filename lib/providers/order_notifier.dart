import 'package:flutter/material.dart';

class OrderNotifier extends ChangeNotifier {
  void notifyNewOrder() {
    notifyListeners();
  }
}
