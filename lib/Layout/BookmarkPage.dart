import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Layout/DetailArt.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text(
          "THE ARTHECA",
          style: TextStyle(
              fontFamily: 'Serif',
              letterSpacing: 4,
              fontSize: 14,
              fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Streaming data berdasarkan User ID agar real-time
        stream: _supabase
            .from('bookmarks')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId ?? '')
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFAC9362)));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saved Treasures",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Serif',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Your\nArchive",
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Serif',
                    color: Colors.black,
                    height: 1.0,
                    letterSpacing: -2.0,
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 40, height: 3, color: const Color(0xFFAC9362)),
                const SizedBox(height: 48),

                MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 32,
                  crossAxisSpacing: 20,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final art = items[index];
                    return _buildArtCard(art);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtCard(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailArtPage(objectId: item['object_id']))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                ),
              ),
            ),
            // Ganti bagian di dalam _buildArtCard (tombol delete)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () async {
                  try {
                    // Hapus berdasarkan ID unik di tabel bookmarks
                    await _supabase.from('bookmarks').delete().eq('id', item['id']);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Artwork removed from archive'), duration: Duration(seconds: 1)),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error deleting: $e");
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          item['title'] ?? 'Untitled',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
            color: Color(0xFF111111),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item['artist'] ?? 'Unknown Artist',
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Your archive is currently empty.", style: TextStyle(fontFamily: 'Serif', color: Colors.grey)),
        ],
      ),
    );
  }
}