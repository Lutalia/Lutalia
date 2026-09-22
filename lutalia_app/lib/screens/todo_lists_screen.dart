import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoListsScreen extends StatefulWidget {
  final String userId;

  const TodoListsScreen({super.key, required this.userId});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  DateTime todayMidnight = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  String _selectedCategory = 'Arbeit';

  // Exakte Lutalia Farbpalette
  final Color _darkBrown = const Color(0xFF5E4940);
  final Color _mediumBrown = const Color(0xFF8C7363);
  final Color _taupe = const Color(0xFFD6CBB9);
  final Color _lightBeige = const Color(0xFFF5EDE5);
  final Color _cardBackground = const Color(0xFFFDFCFA);

  @override
  void initState() {
    super.initState();
    _selectedDay = todayMidnight;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Funktion zum Hinzufügen eines neuen Eintrags
  void _addNewTask() {
    if (_titleController.text.trim().isEmpty) return;

    final targetDate = _selectedDay ?? todayMidnight;

    FirebaseFirestore.instance.collection('todos').add({
      'title': _titleController.text.trim(),
      'text': _textController.text.trim(),
      'category': _selectedCategory,
      'date': Timestamp.fromDate(targetDate),
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': widget.userId,
    });

    _titleController.clear();
    _textController.clear();
    Navigator.of(context).pop();
  }

  // Dialog zum Erstellen eines Eintrags
  void _showAddTaskDialog({String? initialCategory}) {
    if (initialCategory != null) {
      _selectedCategory = initialCategory;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Neuer Eintrag (${DateFormat('dd.MM.yyyy').format(_selectedDay ?? todayMidnight)})',
            style: TextStyle(color: _darkBrown, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: _lightBeige,
                  decoration: InputDecoration(
                    labelText: 'Kategorie',
                    labelStyle: TextStyle(color: _mediumBrown),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _taupe),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                  items: ['Arbeit', 'Haushalt', 'Gesundheit', 'Freunde & Familie', 'Sonstiges']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: _darkBrown))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Titel',
                    labelStyle: TextStyle(color: _mediumBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notiz / Beschreibung (optional)',
                    labelStyle: TextStyle(color: _mediumBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen', style: TextStyle(color: _mediumBrown)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _addNewTask,
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDay = _selectedDay ?? todayMidnight;
    
    // Heutiges Datum für den automatischen Mitternachts-Reset
    final now = DateTime.now();
    final currentMidnight = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: _lightBeige,
      appBar: AppBar(
        backgroundColor: _cardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: _darkBrown),
        title: Text(
          'Meilensteine & Planung',
          style: TextStyle(fontFamily: 'Cinzel', color: _darkBrown, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Vergrößertes Banner oben
            SizedBox(
              width: double.infinity,
              height: 260,
              child: Image.asset(
                'assets/images/meilensteine.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // 2. Klickbare Kategorien (nach rechts scrollbar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Kategorien (Antippen zum Erstellen)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkBrown,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 95,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: [
                  _buildCategoryItem(Icons.work, 'Arbeit', const Color(0xFFC88A65)),
                  _buildCategoryItem(Icons.home, 'Haushalt', const Color(0xFF739E82)),
                  _buildCategoryItem(Icons.favorite, 'Gesundheit', const Color(0xFFD9777F)),
                  _buildCategoryItem(Icons.people, 'Freunde & Familie', const Color(0xFFD4AF37)),
                  _buildCategoryItem(Icons.star, 'Sonstiges', _mediumBrown),
                ],
              ),
            ),
            Divider(height: 35, thickness: 1, color: _taupe.withOpacity(0.5)),

            // 3. Heutige Einträge (Resettet sich automatisch um 00:00 Uhr)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Heutige Einträge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBrown),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(now),
                    style: TextStyle(fontSize: 13, color: _mediumBrown, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('todos')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Heute noch keine Einträge vorhanden.', style: TextStyle(color: _mediumBrown)),
                  );
                }

                // Filter für den heutigen Tag
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['date'] as Timestamp?;
                  if (timestamp == null) return false;
                  final d = timestamp.toDate();
                  final itemDate = DateTime(d.year, d.month, d.day);
                  return itemDate.isAtSameMomentAs(currentMidnight);
                }).toList();

                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Für heute sind noch keine Aufgaben eingetragen.', style: TextStyle(color: _mediumBrown)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final text = data['text'] ?? '';
                    final category = data['category'] ?? 'Allgemein';
                    final isCompleted = data['isCompleted'] ?? false;
                    
                    final timestamp = data['date'] as Timestamp?;
                    final dateFormatted = timestamp != null
                        ? DateFormat('dd.MM.yyyy').format(timestamp.toDate())
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      color: _cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _taupe.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: _darkBrown,
                          value: isCompleted,
                          onChanged: (bool? value) {
                            doc.reference.update({'isCompleted': value ?? false});
                          },
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                  color: isCompleted ? Colors.grey : _darkBrown,
                                ),
                              ),
                            ),
                            if (dateFormatted.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  dateFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _mediumBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: TextStyle(color: Colors.brown[700], fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _taupe.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 10, color: _darkBrown, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            doc.reference.delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Reduzierter Abstand nach oben zum letzten Element
            Divider(height: 15, thickness: 1, color: _taupe.withOpacity(0.5)),
            const SizedBox(height: 4),

            // 4. Alltag-Bild nah am oberen Block
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/fee/alltag.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Mehr Abstand nach unten zum Kalender
            const SizedBox(height: 36),

            // 5. Edler Kalender
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Kalenderübersicht',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBrown),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _taupe.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: _darkBrown.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: _taupe,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: _darkBrown,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: _mediumBrown),
                  defaultTextStyle: TextStyle(color: _darkBrown),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: _darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
                  leftChevronIcon: Icon(Icons.chevron_left, color: _darkBrown),
                  rightChevronIcon: Icon(Icons.chevron_right, color: _darkBrown),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 6. Einträge für den im Kalender ausgewählten Tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Einträge für: ${DateFormat('dd.MM.yyyy').format(activeDay)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkBrown,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, size: 32, color: _mediumBrown),
                    onPressed: () => _showAddTaskDialog(),
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('todos')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Keine Einträge für diesen Tag.', style: TextStyle(color: _mediumBrown)),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['date'] as Timestamp?;
                  if (timestamp == null) return false;
                  final d = timestamp.toDate();
                  return d.year == activeDay.year &&
                      d.month == activeDay.month &&
                      d.day == activeDay.day;
                }).toList();

                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('An diesem Tag ist nichts geplant.', style: TextStyle(color: _mediumBrown)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final text = data['text'] ?? '';
                    final category = data['category'] ?? 'Allgemein';
                    final isCompleted = data['isCompleted'] ?? false;
                    
                    final timestamp = data['date'] as Timestamp?;
                    final dateFormatted = timestamp != null
                        ? DateFormat('dd.MM.yyyy').format(timestamp.toDate())
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      color: _cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _taupe.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: _darkBrown,
                          value: isCompleted,
                          onChanged: (bool? value) {
                            doc.reference.update({'isCompleted': value ?? false});
                          },
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                  color: isCompleted ? Colors.grey : _darkBrown,
                                ),
                              ),
                            ),
                            if (dateFormatted.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  dateFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _mediumBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: TextStyle(color: Colors.brown[700], fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _taupe.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 10, color: _darkBrown, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            doc.reference.delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Großer, angenehmer Abstand am ganz unteren Ende der Seite (erhöht auf 70)
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  // Widget für anklickbare Kategorien
  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => _showAddTaskDialog(initialCategory: label),
      child: Container(
        width: 95,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _taupe.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _darkBrown,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}