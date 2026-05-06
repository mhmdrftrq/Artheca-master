import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailArtPage extends StatefulWidget {
  final int objectId; // ID unik dari API The Met

  const DetailArtPage({super.key, required this.objectId});

  @override
  State<DetailArtPage> createState() => _DetailArtPageState();
}

class _DetailArtPageState extends State<DetailArtPage> {
  late Future<Map<String, dynamic>> _artDetail;

  @override
  void initState() {
    super.initState();
    _artDetail = _fetchArtDetail();
  }

  Future<Map<String, dynamic>> _fetchArtDetail() async {
    final response = await http.get(
      Uri.parse(
        'https://collectionapi.metmuseum.org/public/collection/v1/objects/${widget.objectId}',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat detail karya seni');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'THE ARTHECA',
          style: TextStyle(
            color: Color(0xFFAC9362),
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Color(0xFFAC9362)),
            onPressed: () {
              // Nanti logic simpan ke database Supabase di sini
              print("Menyimpan karya ID: ${widget.objectId}");
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _artDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFAC9362)),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Gagal memuat data. Periksa koneksi lo."),
            );
          }

          final art = snapshot.data!;
          final String imgUrl = art['primaryImage'] != ""
              ? art['primaryImage']
              : 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?q=80&w=500';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER IMAGE & FLOATING TITLE (Sesuai Design Lo)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 450,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imgUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xFFAC9362),
                              width: 5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EXHIBITION ROOM ${art['objectID'] % 100}",
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              art['title'] ?? 'Untitled Masterpiece',
                              style: const TextStyle(
                                fontSize: 22,
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // 2. CONTENT DESCRIPTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "A Study in",
                        style: TextStyle(
                          fontSize: 26,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      Text(
                        art['culture'] != "" ? art['culture'] : "Global Art",
                        style: const TextStyle(
                          fontSize: 30,
                          fontFamily: 'Georgia',
                          color: Color(0xFFAC9362),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Dinamis Deskripsi
                      Text(
                        "This piece, identified as ${art['objectName'] ?? 'art'}, is a remarkable example of ${art['department'] ?? 'the collection'}. "
                        "Dated around ${art['objectDate'] ?? 'an unknown period'}, it showcases the expertise of ${art['artistDisplayName'] != "" ? art['artistDisplayName'] : 'an unidentified master'}.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.7),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "The medium used is ${art['medium'] ?? 'varied materials'}. It was originally acquired as part of the ${art['creditLine'] ?? 'Museum Collection'}.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.7),
                          height: 1.7,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 3. MINI INFO TABLE
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.grey[100],
                        child: Column(
                          children: [
                            _buildInfoRow(
                              "Accession Number",
                              art['accessionNumber'] ?? "-",
                            ),
                            _buildInfoRow(
                              "Dimensions",
                              art['dimensions'] ?? "Not specified",
                            ),
                            _buildInfoRow(
                              "Repository",
                              art['repository'] ?? "The Met",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
