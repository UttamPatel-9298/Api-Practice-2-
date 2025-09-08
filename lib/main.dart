import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wikipedia Search',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WikipediaSearchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WikipediaSearchPage extends StatefulWidget {
  const WikipediaSearchPage({super.key});

  @override
  State<WikipediaSearchPage> createState() => _WikipediaSearchPageState();
}

class _WikipediaSearchPageState extends State<WikipediaSearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _title;
  String? _summary;
  String? _imageUrl;

  Future<void> _searchWikipedia(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _title = null;
      _summary = null;
      _imageUrl = null;
    });

    final url = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'prop': 'extracts|pageimages',
      'exintro': 'true',
      'explaintext': 'true',
      'piprop': 'thumbnail',
      'pithumbsize': '500',
      'generator': 'search',
      'gsrsearch': searchTerm,
      'gsrlimit': '1',
      'origin': '*',
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'];

        if (pages != null && pages.isNotEmpty) {
          final pageId = pages.keys.first;
          final pageData = pages[pageId];

          if (pageId == '-1') {
            setState(() {
              _error = 'No results found for "$searchTerm".';
            });
            return;
          }

          setState(() {
            _title = pageData['title'] ?? 'No title found';
            _summary = pageData['extract'] ?? 'No summary found.';
            _imageUrl = pageData['thumbnail']?['source'];
          });
        } else {
          setState(() {
            _error = 'No results found for "$searchTerm".';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wikipedia Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a search term',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchWikipedia(_controller.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) => _searchWikipedia(value),
            ),
            const SizedBox(height: 20),

            Expanded(child: _buildResultView()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    } else if (_title != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _title!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (_imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  _imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            Text(
              _summary!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Search for a topic to see results.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
  }
}
