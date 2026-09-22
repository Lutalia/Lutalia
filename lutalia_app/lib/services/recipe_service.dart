import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class RecipeDetail {
  final int id;
  final String title;
  final String imageUrl;
  final String fullRecipeHtml;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.fullRecipeHtml,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final title = json['title']?['rendered'] ?? '';
    String imageUrl = '';

    if (json['_embedded']?['wp:featuredmedia'] != null &&
        (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty) {
      imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'] ?? '';
    }

    final rawHtml = json['content']?['rendered'] ?? '';
    final document = html_parser.parse(rawHtml);

    final wprmContainer = document.querySelector('.wprm-recipe-container') ?? 
                          document.querySelector('.wprm-recipe') ?? 
                          document.body;

    wprmContainer?.querySelectorAll('.wprm-recipe-buttons, .wprm-recipe-image').forEach((e) => e.remove());

    return RecipeDetail(
      id: json['id'] ?? 0,
      title: title,
      imageUrl: imageUrl,
      fullRecipeHtml: wprmContainer?.innerHtml ?? rawHtml,
    );
  }
}

class RecipeService {
  final String _postsUrl = 'https://lutalia.de/wp-json/wp/v2/posts?_embed&per_page=50';

  Future<List<RecipeDetail>> fetchRecipes() async {
    final response = await http.get(
      Uri.parse(_postsUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);

      // FILTER: Nur Beiträge behalten, die ein WPRM-Rezept enthalten!
      final recipeJsonList = jsonList.where((json) {
        final content = json['content']?['rendered'] ?? '';
        return content.contains('wprm-recipe');
      }).toList();

      return recipeJsonList.map((json) => RecipeDetail.fromJson(json)).toList();
    } else {
      throw Exception('Fehler beim Laden der Rezepte (Status: ${response.statusCode})');
    }
  }
}