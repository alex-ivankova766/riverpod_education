import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

@immutable
class Purchase {
  const Purchase({
    required this.description,
    required this.id,
    this.purchased = false,
  });

  final String id;
  final String description;
  final bool purchased;

  @override
  String toString() {
    return 'Purchase(description: $description, purchased: $purchased)';
  }
}

class PurchasesList extends Notifier<List<Purchase>> {
  @override
  List<Purchase> build() => [];

  void add(String description) {
    state = [
      ...state,
      Purchase(
        id: _uuid.v4(),
        description: description,
      ),
    ];
  }

  void toggle(String id) {
    state = [
      for (final purchase in state)
        if (purchase.id == id)
          Purchase(
            id: purchase.id,
            purchased: !purchase.purchased,
            description: purchase.description,
          )
        else
          purchase,
    ];
  }

  void edit({required String id, required String description}) {
    state = [
      for (final purchase in state)
        if (purchase.id == id)
          Purchase(
            id: purchase.id,
            purchased: purchase.purchased,
            description: description,
          )
        else
          purchase,
    ];
  }

  void remove(Purchase target) {
    state = state.where((purchase) => purchase.id != target.id).toList();
  }
}
