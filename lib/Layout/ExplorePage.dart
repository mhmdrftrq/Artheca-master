import 'package:artheca/Layout/SearchResult.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'DepartmentDetailPage.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9F8F6);
  static const accentGold = Color(0xFFAC9362);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFEEEEEE);
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();

  // Kita buat list kosong dulu, nanti diisi dari API
  List<dynamic> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://collectionapi.metmuseum.org/public/collection/v1/departments',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _departments = data['departments'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error Fetching Departments: $e");
    }
  }

  String _getCategoryThumb(int id) {
    Map<int, String> customImages = {
      1: 'https://images.metmuseum.org/CRDImages/ad/original/DP-20230-001.jpg', // American Decorative Arts
      3: 'https://images.metmuseum.org/CRDImages/as/original/DP158913.jpg', // Ancient Near Eastern Art
      4: 'https://images.metmuseum.org/CRDImages/aa/original/DP219113.jpg', // Arms and Armor
      5: 'https://images.metmuseum.org/CRDImages/ao/original/DP102026.jpg', // Arts of Africa, Oceania, and the Americas
      6: 'https://images.metmuseum.org/CRDImages/as/original/DP152899.jpg', // Asian Art
      7: 'https://images.metmuseum.org/CRDImages/cl/original/DP102839.jpg', // The Cloisters
      8: 'https://images.metmuseum.org/CRDImages/cr/original/DP221516.jpg', // Costumes
      9: 'https://images.metmuseum.org/CRDImages/dp/original/DP145942.jpg', // Drawings and Prints
      10: 'https://images.metmuseum.org/CRDImages/eg/original/DP242074.jpg', // Egyptian Art
      11: 'https://images.metmuseum.org/CRDImages/ep/original/DT1567.jpg', // European Paintings
      12: 'https://images.metmuseum.org/CRDImages/es/original/DP-14283-001.jpg', // European Sculpture
      13: 'https://images.metmuseum.org/CRDImages/gr/original/DP151333.jpg', // Greek and Roman Art
      14: 'https://images.metmuseum.org/CRDImages/is/original/DP231713.jpg', // Islamic Art
      15: 'https://images.metmuseum.org/CRDImages/ci/original/DP135334.jpg', // Robert Lehman Collection
      17: 'https://images.metmuseum.org/CRDImages/ma/original/DP130999.jpg', // Medieval Art
      18: 'https://images.metmuseum.org/CRDImages/mi/original/DP157455.jpg', // Musical Instruments
      19: 'https://images.metmuseum.org/CRDImages/ph/original/DP-19515-001.jpg', // Photographs
      21: 'https://images.metmuseum.org/CRDImages/md/original/DP142345.jpg', // Modern Art
    };

    // Kalau ID-nya gak ada di daftar, kita kasih gambar museum random biar tetep estetik
    return customImages[id] ??
        'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?q=80&w=500';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 20),
                        _buildTitle(),
                        const SizedBox(height: 32),
                        _buildSearchBar(),
                        const SizedBox(height: 40),
                        const Text(
                          'ALL DEPARTMENTS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryGrid(),

                        // Grid sekarang pake data API
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _departments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final dept = _departments[index];
        final String imgUrl = _getCategoryThumb(dept['departmentId']);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DepartmentDetailPage(
                  deptId: dept['departmentId'],
                  deptName: dept['displayName'],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    // Tambahin error builder biar kalo gambar mati gak item doang
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[300]),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                    child: Text(
                      dept['displayName'].toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'THE ARTHECA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: AppColors.accentGold,
            ),
          ),
          const Icon(
            Icons.notes_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore the',
          style: TextStyle(fontSize: 28, color: AppColors.textPrimary),
        ),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'Georgia',
              color: Colors.black,
              height: 1.1,
            ),
            children: [
              TextSpan(text: 'Complete '),
              TextSpan(
                text: 'Gallery',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            // Pindah ke halaman hasil pencarian
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultPage(searchQuery: query),
              ),
            );
          }
        },
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.accentGold,
        decoration: const InputDecoration(
          hintText: 'Search artworks, artists...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }
}
