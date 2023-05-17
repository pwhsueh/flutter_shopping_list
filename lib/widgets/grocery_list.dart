import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-6a28d-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Could not load items.');
    }
    if (response.body == 'null') {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    print(listData);
    final List<GroceryItem> loadedItems = [];
    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;

    // setState(() {
    //   _errorMessage =
    //       'Something went wrong. Could not load items.Pleae try again later.';
    // });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItemScreen()));
    if (newItem == null) {
      return;
    }
    // setState(() {
    //   _groceryItems.add(newItem);
    // });
    // _loadItems();
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final url = Uri.https('flutter-prep-6a28d-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final reponse = await http.delete(url);
    if (reponse.statusCode >= 400) {
      setState(() {
        _errorMessage = 'Could not delete item.Pleae try again later.';
      });
    } else {
      setState(() {
        _groceryItems.remove(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        // body: contentWidget,
        body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(snapshot.error.toString()),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                            _loadItems();
                          },
                          child: const Text('Try again'))
                    ],
                  ),
                );
              }
              if (snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [Text('No items added yet.')],
                  ),
                );
              }
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: ((context, index) {
                    return Dismissible(
                      onDismissed: (direction) {
                        _removeItem(snapshot.data![index]);
                      },
                      key: ValueKey(snapshot.data![index].id),
                      child: ListTile(
                        title: Text(snapshot.data![index].name),
                        leading: Container(
                          width: 24,
                          height: 24,
                          color: snapshot.data![index].category.color,
                        ),
                        trailing:
                            Text(snapshot.data![index].quantity.toString()),
                      ),
                    );
                  }));
            }
          },
        ));
  }
}
