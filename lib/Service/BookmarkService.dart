import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/ArtModel.dart';

class BookmarkService {
  final _supabase = Supabase.instance.client;

  Future<void> saveBookmark(ArtModel art) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('bookmarks').upsert({
        'user_id': user.id,
        'object_id': art.objectID,
        'title': art.title,
        'image_url': art.imageUrl,
        'artist': art.artist,
        'department': art.department,
      });
    } catch (e) {
      throw Exception('Gagal menyimpan bookmark: $e');
    }
  }

  Future<bool> isBookmarked(int objectId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('bookmarks')
        .select()
        .match({'user_id': user.id, 'object_id': objectId})
        .maybeSingle();

    return response != null;
  }

  Future<void> removeBookmark(int objectId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('bookmarks')
          .delete()
          .match({
        'user_id': user.id,
        'object_id': objectId
      });
    } catch (e) {
      throw Exception('Gagal menghapus data: $e');
    }
  }
}