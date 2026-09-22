import 'package:flutter/material.dart';

class FemBalanceCommunityScreen extends StatefulWidget {
  const FemBalanceCommunityScreen({super.key});

  @override
  State<FemBalanceCommunityScreen> createState() =>
      _FemBalanceCommunityScreenState();
}

class _FemBalanceCommunityScreenState extends State<FemBalanceCommunityScreen> {
  final Color roseLight = const Color(0xFFF3C9D8);
  final Color roseMid = const Color(0xFFE8AFC4);
  final Color roseDark = const Color(0xFFD9A2B8);
  final Color roseDeep = const Color(0xFFC98FA8);
  final Color latteBg = const Color(0xFFF4E6DE);
  final Color latteText = const Color(0xFFD19884);

  // Dummy Posts (später Firestore)
  List<Map<String, dynamic>> posts = [
    {
      "user": "Anonym",
      "text": "Wie geht es euch in der Lutealphase? Ich fühle mich oft sensibler.",
      "time": "vor 2 Std"
    },
    {
      "user": "Anonym",
      "text": "Hat jemand Tipps für sanfte Workouts während der Menstruation?",
      "time": "vor 5 Std"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latteBg,
      appBar: AppBar(
        backgroundColor: roseLight,
        elevation: 0,
        title: const Text(
          "FemBalance Community",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: roseLight,
        onPressed: _openCreatePostDialog,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _postCard(
            user: post["user"],
            text: post["text"],
            time: post["time"],
          );
        },
      ),
    );
  }

  Widget _postCard({
    required String user,
    required String text,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roseLight, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user,
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: latteText,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Post Text
          Text(
            text,
            style: const TextStyle(
              fontFamily: "NewFirst",
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Like + Comment (später erweiterbar)
          Row(
            children: [
              Icon(Icons.favorite_border, color: roseDark, size: 22),
              const SizedBox(width: 14),
              Icon(Icons.chat_bubble_outline, color: roseDark, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  void _openCreatePostDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Beitrag erstellen",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: latteText,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Was möchtest du teilen?",
              hintStyle: TextStyle(
                fontFamily: "NewFirst",
                color: Colors.black54,
              ),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                "Abbrechen",
                style: TextStyle(fontFamily: "Cinzel"),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                "Posten",
                style: TextStyle(
                  fontFamily: "Cinzel",
                  color: latteText,
                ),
              ),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    posts.insert(0, {
                      "user": "Anonym",
                      "text": text,
                      "time": "gerade eben",
                    });
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
