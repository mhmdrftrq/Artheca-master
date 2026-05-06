import 'package:artheca/Layout/DetailArt.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan ini
import '../Models/ArtModel.dart';
import '../Service/ApiService.dart';
import '../Service/BookmarkService.dart'; // Tambahkan ini

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const accentGold = Color(0xFFAC9362);
  static const textPrimary = Color(0xFF1C1C1C);
}

class DepartmentDetailPage extends StatefulWidget {
  final int deptId;
  final String deptName;
  const DepartmentDetailPage({super.key, required this.deptId, required this.deptName});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  final ApiService _apiService = ApiService();
  final BookmarkService _bookmarkService = BookmarkService(); // Inisialisasi
  final _supabase = Supabase.instance.client;

  List<ArtModel> _artList = [];
  bool _isLoading = true;
  Set<int> _bookmarkedIds = {}; // State untuk simpan status bookmark

  @override
  void initState() {
    super.initState();
    _loadDepartmentArt();
  }

  Future<void> _loadDepartmentArt() async {
    try {
      // 1. Ambil data bookmark yang sudah ada biar ikon langsung berwarna
      final userId = _supabase.auth.currentUser?.id;
      final existingBookmarks = await _supabase
          .from('bookmarks')
          .select('object_id')
          .eq('user_id', userId ?? '');

      final Set<int> savedIds = (existingBookmarks as List)
          .map((item) => item['object_id'] as int)
          .toSet();

      // 2. Ambil daftar ID Departemen
      final ids = await _apiService.getObjectIds(widget.deptId);
      final targetIds = ids.take(15).toList();

      // 3. Ambil detail secara paralel
      final requests = targetIds.map((id) => _apiService.getArtDetail(id)).toList();
      final results = await Future.wait(requests);

      final List<ArtModel> tempDetails = results
          .whereType<ArtModel>()
          .where((art) => art.imageUrl.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _artList = tempDetails;
          _bookmarkedIds = savedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi Toggle Bookmark
  void _handleSaveBookmark(ArtModel art) async {
    final bool isAlreadyBookmarked = _bookmarkedIds.contains(art.objectID);

    try {
      if (isAlreadyBookmarked) {
        await _supabase.from('bookmarks').delete().eq('object_id', art.objectID);
        setState(() => _bookmarkedIds.remove(art.objectID));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${art.title}" from Bookmarks'), backgroundColor: Colors.black87),
          );
        }
      } else {
        await _bookmarkService.saveBookmark(art);
        setState(() => _bookmarkedIds.add(art.objectID));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved "${art.title}" to Bookmarks'),
              backgroundColor: AppColors.accentGold,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Bookmark Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            widget.deptName.toUpperCase(),
            style: const TextStyle(fontFamily: 'Georgia', color: Colors.black, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.62, // Sedikit disesuaikan untuk ruang teks
        ),
        itemCount: _artList.length,
        itemBuilder: (context, index) {
          final art = _artList[index];
          final bool isBookmarked = _bookmarkedIds.contains(art.objectID);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      // Area Gambar yang bisa diklik ke Detail
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailArtPage(objectId: art.objectID),
                            ),
                          );
                        },
                        child: Positioned.fill(
                          child: Image.network(
                            art.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // Tombol Bookmark Melayang
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _handleSaveBookmark(art),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                            ),
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              size: 16,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                  art.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontFamily: 'Georgia'
                  )
              ),
              const SizedBox(height: 4),
              Text(
                  art.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)
              ),
            ],
          );
        },
      ),
    );
  }
}