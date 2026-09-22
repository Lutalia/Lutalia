import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final String listId;
  final String listTitle;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listTitle,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  List<ShoppingItem> _items = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await ShoppingListService.getItemsForList(widget.listId);
    setState(() {
      _items = items;
    });
  }

  void _addItem() async {
    if (_textController.text.isNotEmpty) {
      await ShoppingListService.addItemToList(widget.listId, _textController.text);
      _textController.clear();
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A3E33)),
        title: Text(
          widget.listTitle,
          style: const TextStyle(
            color: Color(0xFF4A3E33),
            fontFamily: 'Cinzel',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFF4A3E33),
            ),
            tooltip: 'Erledigte löschen',
            onPressed: () async {
              await ShoppingListService.clearDoneInList(widget.listId);
              _loadItems();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Color(0xFF332A22), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Etwas hinzufügen...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  backgroundColor: const Color(0xFF8A7A6A),
                  elevation: 0,
                  onPressed: _addItem,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Diese Einkaufsliste ist noch leer.\nFüge Gegenstände oder Zutaten hinzu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5A4E44),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: ListTile(
                            leading: Checkbox(
                              activeColor: const Color(0xFF8A7A6A),
                              value: item.isDone,
                              onChanged: (_) async {
                                await ShoppingListService.toggleItem(item.id);
                                _loadItems();
                              },
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                color: item.isDone ? Colors.grey.shade500 : const Color(0xFF332A22),
                                fontWeight: item.isDone ? FontWeight.normal : FontWeight.w600,
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF8A7A6A),
                              ),
                              onPressed: () async {
                                await ShoppingListService.deleteItem(item.id);
                                _loadItems();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}