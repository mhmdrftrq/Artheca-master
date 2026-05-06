import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password, String fullName) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = res.user;

    if (user != null) {
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'bio': 'Art Enthusiast',
        });
      } catch (e) {
        print("Gagal insert ke profiles tapi akun auth aman: $e");
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('bookmarks')
        .select('''
        id,
        artworks (
          id,
          title,
          image_url,
          artist
        )
      ''')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        final newData = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'Curator',
          'bio': 'Official Art Curator',
        };
        await _supabase.from('profiles').insert(newData);
        return newData;
      }

      return response;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }
}