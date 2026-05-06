import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'DetailArt.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const accentGold = Color(0xFFAC9362);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF757575);
}

class SearchResultPage extends StatefulWidget {
  final String searchQuery;
  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _searchController;
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  int _totalFound = 0;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController = TextEditingController(text: _currentQuery);
    _performSearch(_currentQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://collectionapi.metmuseum.org/public/collection/v1/search?q=$query&hasImages=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> objectIds = data['objectIDs'] ?? [];

        if (objectIds.isEmpty) {
          if (mounted)
            setState(
              () => {_searchResults = [], _isLoading = false, _totalFound = 0},
            );
          return;
        }

        final idsToFetch = objectIds.take(150).toList();
        final List<Future<http.Response>> requests = idsToFetch.map((id) {
          return http.get(
            Uri.parse(
              'https://collectionapi.metmuseum.org/public/collection/v1/objects/$id',
            ),
          );
        }).toList();

        final responses = await Future.wait(requests);
        List<dynamic> tempResults = [];
        String lowerQuery = query.toLowerCase().trim();

        for (var res in responses) {
          if (res.statusCode == 200) {
            final item = json.decode(res.body);
            String title = (item['title'] ?? "").toString().toLowerCase();
            String artist = (item['artistDisplayName'] ?? "")
                .toString()
                .toLowerCase();
            List<dynamic> tags = item['tags'] ?? [];
            bool hasMatchingTag = tags.any(
              (tag) =>
                  tag['term'].toString().toLowerCase().contains(lowerQuery),
            );

            if (title.contains(lowerQuery) ||
                artist.contains(lowerQuery) ||
                hasMatchingTag) {
              if (item['primaryImageSmall'] != null &&
                  item['primaryImageSmall'] != "") {
                tempResults.add(item);
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = tempResults;
            _totalFound = tempResults.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EXPLORE ARTHECA',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) => _performSearch(value),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search for artists, styles, or tags...",
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.accentGold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- CONTENT SECTION ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  )
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found $_totalFound masterpieces for "${_currentQuery.toUpperCase()}"',
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 15,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final art = _searchResults[index];
                            return _buildArtCard(art);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtCard(Map<String, dynamic> art) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailArtPage(objectId: art['objectID']),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              art['primaryImageSmall'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(height: 150, color: Colors.grey[50]);
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            art['title'] ?? 'Untitled',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Georgia',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            art['artistDisplayName'] != ""
                ? art['artistDisplayName']
                : 'Unknown Artist',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No exact matches for "${_searchController.text}"',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
