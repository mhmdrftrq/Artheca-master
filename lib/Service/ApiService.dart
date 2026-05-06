import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/ArtModel.dart';

class ApiService {
  static const String baseUrl = "https://collectionapi.metmuseum.org/public/collection/v1";

  Future<List<int>> getObjectIds(int departmentId) async {
    final response = await http.get(Uri.parse('$baseUrl/objects?departmentIds=$departmentId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<int>.from(data['objectIDs'].take(20)); // Kita ambil 20 dulu biar gak berat
    }
    return [];
  }

  Future<ArtModel?> getArtDetail(int objectId) async {
    final response = await http.get(Uri.parse('$baseUrl/objects/$objectId'));
    if (response.statusCode == 200) {
      return ArtModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  static const String _key = 'bookmarked_arts';

  Future<void> toggleBookmark(ArtModel art) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList(_key) ?? [];

    int index = savedItems.indexWhere((item) => json.decode(item)['objectID'] == art.objectID);

    if (index >= 0) {
      savedItems.removeAt(index);
    } else {
      savedItems.add(json.encode(art.toJson()));
    }

    await prefs.setStringList(_key, savedItems);
  }

  Future<List<ArtModel>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList(_key) ?? [];
    return savedItems.map((item) => ArtModel.fromJson(json.decode(item))).toList();
  }
}