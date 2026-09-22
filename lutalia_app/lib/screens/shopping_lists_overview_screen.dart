import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsOverviewScreen extends StatefulWidget {
  const ShoppingListsOverviewScreen({super.key});

  @override
  State<ShoppingListsOverviewScreen> createState() => _ShoppingListsOverviewScreenState();
}

class _ShoppingListsOverviewScreenState extends State<ShoppingListsOverviewScreen> {
  List<ShoppingListMeta> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await ShoppingListService.getAllLists();
    setState(() {
      _lists = lists;
      _isLoading = false;
    });
  }

  void _createNewListDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9F6F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Neue Einkaufsliste',
          style: TextStyle(
            color: Color(0xFF4A3E33),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF4A3E33)),
          decoration: InputDecoration(
            hintText: 'Titel der Liste (z.B. Wocheneinkauf)',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF7A6B5D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A7A6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context);
                await ShoppingListService.createNewList(titleController.text);
                _loadLists();
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A3E33)),
        title: const Text(
          'Meine Einkaufslisten',
          style: TextStyle(
            color: Color(0xFF4A3E33),
            fontFamily: 'Cinzel',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ⭐ Bild oben eingefügt
          Center(
            child: Image.asset(
              "assets/fee/küche.png",
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 12),

          // ⭐ Satz in Newfirst
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Alles für deine genussvollen Momente",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Newfirst',
                fontSize: 24,
                color: Color(0xFF4A3E33),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⭐ Die eigentliche Listen-Ansicht
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A7A6A)))
                : _lists.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Noch keine Einkaufslisten vorhanden.\nErstelle jetzt deine erste Liste!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF5A4E44),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _lists.length,
                        itemBuilder: (context, index) {
                          final listMeta = _lists[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(
                                listMeta.title,
                                style: const TextStyle(
                                  color: Color(0xFF332A22),
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Erstellt am: ${listMeta.date}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFA94442)),
                                onPressed: () async {
                                  await ShoppingListService.deleteList(listMeta.id);
                                  _loadLists();
                                },
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShoppingListDetailScreen(
                                      listId: listMeta.id,
                                      listTitle: listMeta.title,
                                    ),
                                  ),
                                );
                                _loadLists();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8A7A6A),
        elevation: 2,
        onPressed: _createNewListDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}