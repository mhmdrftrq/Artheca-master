class ArtModel {
  final int objectID;
  final String title;
  final String artist;
  final String date;
  final String imageUrl;
  final String department;

  ArtModel({
    required this.objectID,
    required this.title,
    required this.artist,
    required this.date,
    required this.imageUrl,
    required this.department,
  });

  // Convert dari JSON API ke Model Kita
  factory ArtModel.fromJson(Map<String, dynamic> json) {
    return ArtModel(
      objectID: json['objectID'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      artist: json['artistDisplayName'] ?? 'Unknown Artist',
      date: json['objectDate'] ?? 'Unknown Date',
      imageUrl: json['primaryImageSmall'] ?? json['primaryImage'] ?? '',
      department: json['department'] ?? '',
    );
  }

  // Buat simpen ke Shared Preferences (Map -> JSON String)
  Map<String, dynamic> toJson() => {
    'objectID': objectID,
    'title': title,
    'artist': artist,
    'date': date,
    'imageUrl': imageUrl,
    'department': department,
  };
}