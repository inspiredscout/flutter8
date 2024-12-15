import 'package:flutter/material.dart';
import 'package:pks9/components/item.dart';
import 'package:pks9/model/product.dart';
import 'package:pks9/pages/add_set_page.dart';
import 'package:pks9/api_service.dart';

class HomePage extends StatefulWidget {
  final Function(Collector) onFavoriteToggle;
  final List<Collector> favoriteSets;
  final Function(Collector) onAddToCart;
  final Function(Collector) onEdit;

  const HomePage({
    super.key,
    required this.onFavoriteToggle,
    required this.favoriteSets,
    required this.onAddToCart,
    required this.onEdit,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  List<dynamic> sets = [];

  Future<void> loadSets() async {
    final fetchedSets = await apiService.getProducts();
    setState(() {
      sets = fetchedSets;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSets();
  }

  Future<void> _addNewSet(Collector set) async {
    try {
      final newSet = await apiService.createProducts(set);
      setState(() {
        sets.add(newSet);
      });
    } catch (e) {
      print("Ошибка добавления сета: $e");
    }
  }

  Future<void> _removeCar(int id) async {
    try {
      await apiService.deleteProduct(id);
      setState(() {
        sets.removeWhere((set) => set.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Сет с ID $id удалена")),
      );
    } catch (e) {
      print("Ошибка удаления сета: $e");
    }
  }

  Future<void> _editCarDialog(BuildContext context, Collector set) async {
    String title = set.title;
    String description = set.description;
    String imageUrl = set.imageUrl;
    String cost = set.cost;
    String article = set.article;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Редактировать сет'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Название'),
                  controller: TextEditingController(text: title),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Описание'),
                  controller: TextEditingController(text: description),
                  onChanged: (value) {
                    description = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'URL картинки'),
                  controller: TextEditingController(text: imageUrl),
                  onChanged: (value) {
                    imageUrl = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Цена'),
                  controller: TextEditingController(text: cost),
                  onChanged: (value) {
                    cost = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Артикул'),
                  controller: TextEditingController(text: article),
                  onChanged: (value) {
                    article = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Сохранить'),
              onPressed: () async {
                if (title.isNotEmpty &&
                    description.isNotEmpty &&
                    cost.isNotEmpty &&
                    article.isNotEmpty) {
                  Collector updatedCar = Collector(
                    set.id,
                    title,
                    description,
                    imageUrl,
                    cost,
                    article,
                  );
                  try {
                    Collector result =
                        await apiService.updateProduct(set.id, updatedCar);
                    setState(() {
                      int index = sets.indexWhere((c) => c.id == set.id);
                      if (index != -1) {
                        sets[index] = result;
                      }
                    });
                    Navigator.of(context).pop();
                  } catch (error) {
                    print('Ошибка при обновлении машины: $error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $error')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Пожалуйста, заполните все поля.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Collectors Set',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          backgroundColor: Colors.deepPurpleAccent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: sets.isNotEmpty
              ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: sets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final set = sets[index];
                    final isFavorite = widget.favoriteSets.contains(set);
                    return GestureDetector(
                      onLongPress: () => _editCarDialog(context, set),
                      child: Dismissible(
                        key: Key(set.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await _removeCar(set.id);
                        },
                        child: ItemNote(
                          collector: set,
                          isFavorite: isFavorite,
                          onFavoriteToggle: () => widget.onFavoriteToggle(set),
                          onAddToCart: () => widget.onAddToCart(set),
                          onEdit: () => _editCarDialog(context, set),
                        ),
                      ),
                    );
                  },
                )
              : const Center(child: Text('Нет доступных сетов')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newCar = await Navigator.push<Collector>(
              context,
              MaterialPageRoute(builder: (context) => const AddSetPage()),
            );
            if (newCar != null) {
              await _addNewSet(newCar);
            }
          },
          child: const Icon(Icons.add,
          color: Colors.white,),
          backgroundColor: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}