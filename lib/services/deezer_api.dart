import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'https://corsproxy.io/?url=https://api.deezer.com';

class DeezerAlbum {
  final int rank;
  final String title;
  final String artist;
  final String coverMedium;
  final String coverBig;
  final String url;
  final String releaseDate;
  final int genreId;

  DeezerAlbum({required this.rank, required this.title, required this.artist,
    required this.coverMedium, required this.coverBig, required this.url,
    required this.releaseDate, this.genreId = 0});
}

class DeezerGenre {
  final int id;
  final String name;
  DeezerGenre({required this.id, required this.name});
}

class DeezerApi {
  static Future<List<DeezerGenre>> getGenres() async {
    final res = await http.get(Uri.parse('$_base/genre'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return (data['data'] as List).map((g) => DeezerGenre(id: g['id'] ?? 0, name: g['name'] ?? '')).toList();
  }

  static Future<List<DeezerAlbum>> getNewReleases({int genreId = 0, int limit = 100}) async {
    final res = await http.get(Uri.parse('$_base/editorial/$genreId/releases?limit=$limit'));
    if (res.statusCode != 200) throw Exception('Failed');
    final data = jsonDecode(res.body);
    final albums = data['data'] as List;
    return albums.asMap().entries.map((e) {
      final a = e.value;
      return DeezerAlbum(
        rank: e.key + 1,
        title: a['title'] ?? '',
        artist: a['artist']?['name'] ?? '',
        coverMedium: a['cover_medium'] ?? '',
        coverBig: a['cover_big'] ?? '',
        url: 'https://www.deezer.com/album/${a['id']}',
        releaseDate: a['release_date'] ?? '',
        genreId: genreId,
      );
    }).toList();
  }

  static Future<List<DeezerAlbum>> searchAlbums(String query, {int limit = 100}) async {
    final res = await http.get(Uri.parse('$_base/search/album?q=${Uri.encodeComponent(query)}&limit=$limit'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return (data['data'] as List).asMap().entries.map((e) {
      final a = e.value;
      return DeezerAlbum(
        rank: e.key + 1,
        title: a['title'] ?? '',
        artist: a['artist']?['name'] ?? '',
        coverMedium: a['cover_medium'] ?? '',
        coverBig: a['cover_big'] ?? '',
        url: a['link'] ?? '',
        releaseDate: '',
      );
    }).toList();
  }
}
