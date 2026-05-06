import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/ArtModel.dart';
import '../Service/ApiService.dart';
import '../Service/BookmarkService.dart';
import '../Layout/DetailArt.dart';
import 'DepartmentDetailPage.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9F8F6);
  static const accentGold = Color(0xFFAC9362);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF757575);
}

class HomePage extends StatefulWidget {
  final VoidCallback? onViewAll;
  const HomePage({super.key, this.onViewAll});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final BookmarkService _bookmarkService = BookmarkService();
  final _supabase = Supabase.instance.client;

  ArtModel? _heroArt;
  List<ArtModel> _featuredArtworks = [];
  Map<String, ArtModel> _deptImages = {};
  bool _isLoading = true;
  Set<int> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final existingBookmarks = await _supabase
          .from('bookmarks')
          .select('object_id')
          .eq('user_id', userId ?? '');

      final Set<int> savedIds = (existingBookmarks as List)
          .map((item) => item['object_id'] as int)
          .toSet();

      Map<String, int> categories = {
        'Egyptian Art': 10,
        'Greek and Roman Art': 13,
        'Asian Art': 6,
        'European Paintings': 11,
      };

      final idRequests = categories.values
          .map((id) => _apiService.getObjectIds(id))
          .toList();
      final allIdsResults = await Future.wait(idRequests);

      List<int> flattenedIds = [];
      Map<String, int> firstIdPerDept = {};

      for (int i = 0; i < allIdsResults.length; i++) {
        String deptName = categories.keys.elementAt(i);
        List<int> ids = allIdsResults[i];
        if (ids.isNotEmpty) {
          firstIdPerDept[deptName] = ids.first;
          flattenedIds.addAll(ids.take(5));
        }
      }

      final detailRequests = flattenedIds
          .map((id) => _apiService.getArtDetail(id))
          .toList();
      final allArtDetails = await Future.wait(detailRequests);
      final validArt = allArtDetails
          .whereType<ArtModel>()
          .where((a) => a.imageUrl.isNotEmpty)
          .toList();

      Map<String, ArtModel> tempDeptImages = {};
      for (var entry in firstIdPerDept.entries) {
        tempDeptImages[entry.key] = validArt.firstWhere(
          (a) => a.objectID == entry.value,
          orElse: () => validArt.first,
        );
      }

      if (mounted) {
        setState(() {
          _featuredArtworks = validArt..shuffle();
          _deptImages = tempDeptImages;
          _heroArt = validArt.isNotEmpty ? validArt[0] : null;
          _bookmarkedIds = savedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSaveBookmark(ArtModel art) async {
    final bool isAlreadyBookmarked = _bookmarkedIds.contains(art.objectID);
    try {
      if (isAlreadyBookmarked) {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('object_id', art.objectID);
        setState(() => _bookmarkedIds.remove(art.objectID));
      } else {
        await _bookmarkService.saveBookmark(art);
        setState(() => _bookmarkedIds.add(art.objectID));
      }
    } catch (e) {
      debugPrint("Bookmark Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _buildHeader(),
                  if (_heroArt != null) _buildHeroSection(_heroArt!),
                  _buildSectionTitle(context, 'Featured Works'),
                  _buildFeaturedCarousel(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    context,
                    'Curated Departments',
                    onTap: widget.onViewAll,
                  ),
                  _buildDepartmentGrid(),
                  const SizedBox(height: 48),
                  _buildSectionTitle(context, 'Discover More'),
                  _buildVerticalGallery(),
                ],
              ),
            ),
    );
  }

  // 1. HERO SECTION - Tombol Save Dihapus
  Widget _buildHeroSection(ArtModel art) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            art.department.toUpperCase(),
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            art.title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32,
              height: 1.1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailArtPage(objectId: art.objectID),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                art.imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. FEATURED CAROUSEL - Tetap bisa di-save (buat fungsionalitas cepat)
  Widget _buildFeaturedCarousel() {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _featuredArtworks.length > 10
            ? 10
            : _featuredArtworks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = _featuredArtworks[index];
          final bool isBookmarked = _bookmarkedIds.contains(item.objectID);

          return SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailArtPage(objectId: item.objectID),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            width: 220,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => _handleSaveBookmark(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 18,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  item.artist,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. DISCOVER MORE - Tombol Save Dihapus (Visual Lebih Bersih)
  Widget _buildVerticalGallery() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _featuredArtworks.take(5).map((art) {
          return Container(
            margin: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailArtPage(objectId: art.objectID),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      art.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  art.department.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  art.title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  art.artist,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    Map<String, int> categories = {
      'Egyptian Art': 10,
      'Greek and Roman Art': 13,
      'Asian Art': 6,
      'European Paintings': 11,
    };
    final List<String> deptNames = categories.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: deptNames.length,
        itemBuilder: (context, index) {
          final name = deptNames[index];
          final art = _deptImages[name];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DepartmentDetailPage(
                  deptId: categories[name]!,
                  deptName: name,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: art != null
                        ? Image.network(art.imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200]),
                  ),
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                  Center(
                    child: Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'THE ARTHECA',
            style: TextStyle(
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGold,
            ),
          ),
          Icon(Icons.notes_rounded),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
