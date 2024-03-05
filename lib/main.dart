import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'purchase.dart';

final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

final purchaseListProvider =
    NotifierProvider<PurchasesList, List<Purchase>>(PurchasesList.new);

enum PurchasesListFilter {
  all,
  active,
  purchased,
}

final purchaseListFilter = StateProvider((_) => PurchasesListFilter.all);

final unpurchasedPurchaseCount = Provider<int>((ref) {
  return ref
      .watch(purchaseListProvider)
      .where((purchase) => !purchase.purchased)
      .length;
});

final filteredPurchases = Provider<List<Purchase>>((ref) {
  final filter = ref.watch(purchaseListFilter);
  final purchases = ref.watch(purchaseListProvider);

  switch (filter) {
    case PurchasesListFilter.purchased:
      return purchases.where((purchase) => purchase.purchased).toList();
    case PurchasesListFilter.active:
      return purchases.where((purchase) => !purchase.purchased).toList();
    case PurchasesListFilter.all:
      return purchases;
  }
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _Home(),
    );
  }
}

class _Home extends HookConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(filteredPurchases);
    final newPurchaseController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const _Title(),
            TextField(
              key: addTodoKey,
              controller: newPurchaseController,
              decoration: const InputDecoration(
                labelText: 'What you need to buy?',
              ),
              onSubmitted: (value) {
                ref.read(purchaseListProvider.notifier).add(value);
                newPurchaseController.clear();
              },
            ),
            const SizedBox(height: 42),
            const _Toolbar(),
            if (purchases.isNotEmpty) const Divider(height: 0),
            for (var i = 0; i < purchases.length; i++) ...[
              if (i > 0) const Divider(height: 0),
              Dismissible(
                key: ValueKey(purchases[i].id),
                onDismissed: (_) {
                  ref.read(purchaseListProvider.notifier).remove(purchases[i]);
                },
                child: ProviderScope(
                  overrides: [
                    _currentPurchase.overrideWithValue(purchases[i]),
                  ],
                  child: const _PurchaseItem(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends HookConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(purchaseListFilter);

    Color? textColorFor(PurchasesListFilter value) {
      return filter == value ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(unpurchasedPurchaseCount)} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: allFilterKey,
            message: 'All purchases',
            child: TextButton(
              onPressed: () => ref.read(purchaseListFilter.notifier).state =
                  PurchasesListFilter.all,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                    textColorFor(PurchasesListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            key: activeFilterKey,
            message: 'Only unpurchased purchases',
            child: TextButton(
              onPressed: () => ref.read(purchaseListFilter.notifier).state =
                  PurchasesListFilter.active,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(PurchasesListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            key: completedFilterKey,
            message: 'Only purchased purchases',
            child: TextButton(
              onPressed: () => ref.read(purchaseListFilter.notifier).state =
                  PurchasesListFilter.purchased,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(PurchasesListFilter.purchased),
                ),
              ),
              child: const Text('Purchased'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'shopping list',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 80,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

final _currentPurchase =
    Provider<Purchase>((ref) => throw UnimplementedError());

class _PurchaseItem extends HookConsumerWidget {
  const _PurchaseItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(_currentPurchase);
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = purchase.description;
          } else {
            ref
                .read(purchaseListProvider.notifier)
                .edit(id: purchase.id, description: textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: purchase.purchased,
            onChanged: (value) =>
                ref.read(purchaseListProvider.notifier).toggle(purchase.id),
          ),
          title: itemIsFocused
              ? TextField(
                  autofocus: true,
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(purchase.description),
        ),
      ),
    );
  }
}

bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(
    () {
      void listener() {
        isFocused.value = node.hasFocus;
      }

      node.addListener(listener);
      return () => node.removeListener(listener);
    },
    [node],
  );

  return isFocused.value;
}
