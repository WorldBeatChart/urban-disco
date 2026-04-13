import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://api.deezer.com';

class DeezerTrack {
  final int rank;
  final String name;
  final String artist;
  final String albumCover;
  final String artistImage;
  final String url;
  final int duration;
  final String preview;

  DeezerTrack({
    required this.rank,
    required this.name,
    required this.artist,
    required this.albumCover,
    required this.artistImage,
    required this.url,
    required this.duration,
    required this.preview,
  });
}

class DeezerArtist {
  final int rank;
  final String name;
  final String imageUrl;
  final String url;

  DeezerArtist({
    required this.rank,
    required this.name,
    required this.imageUrl,
    required this.url,
  });
}

class DeezerApi {
  static Future<List<DeezerTrack>> getChart({int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/chart/0/tracks?limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load chart');
    final data = jsonDecode(res.body);
    final tracks = data['data'] as List;
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      return DeezerTrack(
        rank: e.key + 1,
        name: t['title'] ?? '',
        artist: t['artist']?['name'] ?? '',
        albumCover: t['album']?['cover_medium'] ?? '',
        artistImage: t['artist']?['picture_medium'] ?? '',
        url: t['link'] ?? '',
        duration: t['duration'] ?? 0,
        preview: t['preview'] ?? '',
      );
    }).toList();
  }

  static Future<List<DeezerArtist>> getChartArtists({int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/chart/0/artists?limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load artists');
    final data = jsonDecode(res.body);
    final artists = data['data'] as List;
    return artists.asMap().entries.map((e) {
      final a = e.value;
      return DeezerArtist(
        rank: e.key + 1,
        name: a['name'] ?? '',
        imageUrl: a['picture_medium'] ?? '',
        url: a['link'] ?? '',
      );
    }).toList();
  }

  static Future<List<DeezerTrack>> search(String query, {int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Search failed');
    final data = jsonDecode(res.body);
    final tracks = data['data'] as List;
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      return DeezerTrack(
        rank: e.key + 1,
        name: t['title'] ?? '',
        artist: t['artist']?['name'] ?? '',
        albumCover: t['album']?['cover_medium'] ?? '',
        artistImage: t['artist']?['picture_medium'] ?? '',
        url: t['link'] ?? '',
        duration: t['duration'] ?? 0,
        preview: t['preview'] ?? '',
      );
    }).toList();
  }
}
