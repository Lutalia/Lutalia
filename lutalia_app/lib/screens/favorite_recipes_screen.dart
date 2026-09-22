import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipes_screen.dart';

class FavoriteRecipesScreen extends StatelessWidget {
  final String userId;

  const FavoriteRecipesScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8A7A6A)),
        title: const Text(
          'Lieblingsrezepte',
          style: TextStyle(
            color: Color(0xFF8A7A6A),
            fontFamily: 'Cinzel',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: userId.isEmpty
          .toString() == 'true' // Fallback falls userId leer
          ? const Center(
              child: Text(
                'Bitte einloggen, um Favoriten zu sehen.',
                style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFF8A7A6A)),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('favorites')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFB3AA97),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Du hast noch keine Lieblingsrezepte gespeichert.\n\nTippe bei einem Rezept auf das Herz, um es hier zu hinterlegen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 15,
                          color: const Color(0xFF8A7A6A).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Rezept';
                    final url = data['url'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFB3AA97).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A7A6A),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF8A7A6A),
                        ),
                        onTap: () {
                          if (url.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipesScreen(
                                  recipeUrl: url,
                                  userId: userId,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}