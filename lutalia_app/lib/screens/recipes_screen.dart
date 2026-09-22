import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/recipe_service_favoriten.dart';
import 'favorite_recipes_screen.dart';

class RecipesScreen extends StatefulWidget {
  final String recipeUrl;
  final String userId;

  const RecipesScreen({
    super.key,
    this.recipeUrl = 'https://lutalia.de/rezepte',
    required this.userId,
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _isFavorite = false;
  bool _isMainPage = true;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.recipeUrl;
    _checkIfMainPage(widget.recipeUrl);
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF9F6F0))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            _checkIfMainPage(url);
            _injectStylesAndFixes();
            _checkFavoriteStatus(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            _checkIfMainPage(url);
            _injectStylesAndFixes();
            _checkFavoriteStatus(url);
            
            // Mehrfach-Triggern beim Laden für späte AJAX-Elemente
            Future.delayed(const Duration(milliseconds: 100), () => _injectStylesAndFixes());
            Future.delayed(const Duration(milliseconds: 300), () => _injectStylesAndFixes());
            Future.delayed(const Duration(milliseconds: 700), () => _injectStylesAndFixes());
            Future.delayed(const Duration(milliseconds: 1200), () => _injectStylesAndFixes());
          },
        ),
      );

    _controller.loadRequest(Uri.parse(widget.recipeUrl));
  }

  void _checkIfMainPage(String url) {
    Uri uri = Uri.parse(url);
    String path = uri.path.replaceAll(RegExp(r'/$'), '');
    setState(() {
      _isMainPage = (path.isEmpty || path == '/rezepte');
    });
  }

  Future<void> _checkFavoriteStatus(String url) async {
    if (widget.userId.isEmpty) return;
    bool fav = await RecipeService.isFavorite(widget.userId, url);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
      });
    }
  }

  Future<void> _handleToggleFavorite() async {
    if (widget.userId.isEmpty) return;

    String title = await _controller.runJavaScriptReturningResult("document.title;") as String? ?? "Rezept";
    title = title.replaceAll('"', '');

    await RecipeService.toggleFavorite(widget.userId, _currentUrl, title);
    
    if (!mounted) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Zu den Lieblingsrezepten hinzugefügt' : 'Aus den Lieblingsrezepten entfernt'),
        backgroundColor: const Color(0xFF8A7A6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFavoritesOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoriteRecipesScreen(userId: widget.userId),
      ),
    );
  }

  void _injectStylesAndFixes() {
    _controller.runJavaScript("""
      (function() {
        if (!document.getElementById('lutalia-custom-newfirst-font')) {
          var fontFace = document.createElement('style');
          fontFace.id = 'lutalia-custom-newfirst-font';
          fontFace.innerHTML = '@font-face { font-family: "Newfirst"; src: url("https://lutalia.de/wp-content/uploads/fonts/Newfirst.woff2") format("woff2"), url("https://lutalia.de/wp-content/uploads/fonts/Newfirst.woff") format("woff"); font-display: swap; }';
          document.head.appendChild(fontFace);
        }

        if (!document.getElementById('lutalia-custom-style')) {
          var fontLink = document.createElement('link');
          fontLink.id = 'lutalia-custom-font';
          fontLink.rel = 'stylesheet';
          fontLink.href = 'https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&display=swap';
          document.head.appendChild(fontLink);

          var style = document.createElement('style');
          style.id = 'lutalia-custom-style';
          style.innerHTML = ' \\
            h1, h2, h3, h4, h5, h6, .wprm-recipe-name, .elementor-heading-title:not(.lutalia-force-newfirst) { \\
              font-family: "Cinzel", serif !important; \\
            } \\
            header, .site-header, #masthead, .ast-main-header-wrap, \\
            #cmplz-cookiebanner-container, .cmplz-cookiebanner, \\
            footer, #footer, .footer, .site-footer, #colophon, .elementor-location-footer { \\
              display: none !important; \\
              height: 0 !important; \\
              min-height: 0 !important; \\
              overflow: hidden !important; \\
            } \\
            .lutalia-force-newfirst { \\
              font-family: "Newfirst", cursive, serif !important; \\
              font-size: 26px !important; \\
              max-width: 100% !important; \\
              width: 100% !important; \\
              box-sizing: border-box !important; \\
              word-break: break-word !important; \\
              overflow-wrap: break-word !important; \\
              white-space: normal !important; \\
            } \\
          ';
          document.head.appendChild(style);
        }

        function applyNewfirstFix() {
          var elements = document.querySelectorAll('h1, h2, h3, h4, h5, h6, .elementor-heading-title, span, p, div');
          elements.forEach(function(el) {
            var text = el.innerText ? el.innerText.trim().replace(/\\s+/g, ' ').toUpperCase() : '';
            if (text.includes('DEIN NEUES LIEBLINGSREZEPT WARTET AUF DICH')) {
              if (!el.classList.contains('lutalia-force-newfirst')) {
                el.classList.add('lutalia-force-newfirst');
              }
              // Erzwinge den Style direkt per JS-Attribut, falls CSS überschrieben wird
              el.style.setProperty('font-family', '"Newfirst", cursive, serif', 'important');
              el.style.setProperty('font-size', '26px', 'important');
            }
          });
        }

        applyNewfirstFix();

        // Permanent aktiver Observer, der sofort eingreift, wenn Elementor den DOM neu zeichnet
        if (!window.lutaliaObserverInitialized) {
          window.lutaliaObserverInitialized = true;
          var observer = new MutationObserver(function(mutations) {
            applyNewfirstFix();
          });
          observer.observe(document.body, { childList: true, subtree: true, characterData: true });
        }
      })();
    """);
  }

  Future<void> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      setState(() {
        _isLoading = false;
      });
      _controller.goBack();
      _injectStylesAndFixes();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F6F0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8A7A6A)),
          title: const Text(
            'Rezepte',
            style: TextStyle(
              color: Color(0xFF8A7A6A),
              fontFamily: 'Cinzel',
              fontSize: 18,
            ),
          ),
          actions: [
            if (_isMainPage)
              IconButton(
                icon: const Icon(Icons.favorite, color: Color(0xFF8A7A6A)),
                tooltip: 'Lieblingsrezepte',
                onPressed: _openFavoritesOverview,
              )
            else
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFF8A7A6A),
                ),
                onPressed: _handleToggleFavorite,
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: const Color(0xFFF9F6F0),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB3AA97),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}