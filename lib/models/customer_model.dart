
import 'package:flutter/foundation.dart';

class CustomerModel with ChangeNotifier {
  String? _customerId;

  String? get customerId => _customerId;

  void setCustomerId(String id) {
    _customerId = id;
    print('[CustomerModel] Customer ID set: $id');
    notifyListeners();
  }
}

