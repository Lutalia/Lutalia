import 'package:flutter/material.dart';
import '../screens/lutalia_page.dart';

class GoalsHabitsScreen extends StatefulWidget {
  final String userId;

  const GoalsHabitsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<GoalsHabitsScreen> createState() => _GoalsHabitsScreenState();
}

class _GoalsHabitsScreenState extends State<GoalsHabitsScreen> {
  // Verfügbare Kategorien nach deinen Wünschen
  final List<String> _categories = [
    'Arbeit',
    'Hausarbeit',
    'Freunde & Familie',
    'Freizeit',
    'Sonstiges'
  ];

  String _selectedCategory = 'Arbeit';

  // Liste für Ziele & Gewohnheiten
  final List<GoalHabitItem> _items = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _addItem() {
    if (_descriptionController.text.trim().isEmpty) return;
    setState(() {
      _items.add(GoalHabitItem(
        title: _titleController.text.trim().isEmpty ? 'Mein Ziel' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: DateTime.now(),
      ));
      _descriptionController.clear();
      _titleController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Ziele & Gewohnheiten",
      showBack: true,
      onBackPressed: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stilvoller Intro-Text mit Newfirst
          const Text(
            "Wachse an deinen Visionen",
            style: TextStyle(
              fontFamily: "Newfirst",
              fontSize: 24,
              color: Color(0xFF8A7A6A),
            ),
          ),
          const SizedBox(height: 12),

          // Kategorie-Auswahl (Chips)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF8A7A6A),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFB3AA97),
                    backgroundColor: const Color(0xFFF9F6F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFB3AA97), width: 1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Eingabefelder für Ziel-Titel und Details/Gewohnheit
          TextField(
            controller: _titleController,
            style: const TextStyle(fontFamily: "Cinzel", color: Color(0xFF8A7A6A)),
            decoration: InputDecoration(
              labelText: 'Titel / Vision',
              labelStyle: const TextStyle(fontFamily: "Cinzel", color: Color(0xFF8A7A6A)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB3AA97)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8A7A6A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Neue Gewohnheit oder Schritt...',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB3AA97)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8A7A6A), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB3AA97),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Liste der Ziele & Gewohnheiten
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      "Noch keine Ziele für ${_selectedCategory}.\nSetze dir deinen ersten Meilenstein!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Cinzel",
                        color: Color(0xFF8A7A6A),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      if (item.category != _selectedCategory) return const SizedBox.shrink();
                      
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFB3AA97), width: 0.8),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontFamily: "Cinzel",
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A7A6A),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description, style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(
                                "${item.date.day}.${item.date.month}.${item.date.year}",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: item.isCompleted,
                            activeColor: const Color(0xFFB3AA97),
                            onChanged: (val) {
                              setState(() {
                                item.isCompleted = val ?? false;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class GoalHabitItem {
  String title;
  String description;
  String category;
  DateTime date;
  bool isCompleted;

  GoalHabitItem({
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.isCompleted = false,
  });
}