import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiKey = '83af2d75d16959674b80d2b1546621fa';
const _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

class ChartTrack {
  final int rank;
  final String name;
  final String artist;
  final String imageUrl;
  final int playcount;
  final int listeners;
  final String url;

  ChartTrack({
    required this.rank,
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.playcount,
    required this.listeners,
    required this.url,
  });
}

class ChartArtist {
  final int rank;
  final String name;
  final String imageUrl;
  final int playcount;
  final int listeners;
  final String url;

  ChartArtist({
    required this.rank,
    required this.name,
    required this.imageUrl,
    required this.playcount,
    required this.listeners,
    required this.url,
  });
}

class LastFmApi {
  static Future<List<ChartTrack>> getTopTracks({int limit = 50, int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?method=chart.gettoptracks&api_key=$_apiKey&format=json&limit=$limit&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load charts');
    final data = jsonDecode(res.body);
    final tracks = data['tracks']['track'] as List;
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      final images = t['image'] as List;
      final img = images.isNotEmpty ? images.last['#text'] as String : '';
      return ChartTrack(
        rank: (page - 1) * limit + e.key + 1,
        name: t['name'] ?? '',
        artist: t['artist']?['name'] ?? '',
        imageUrl: img,
        playcount: int.tryParse('${t['playcount']}') ?? 0,
        listeners: int.tryParse('${t['listeners']}') ?? 0,
        url: t['url'] ?? '',
      );
    }).toList();
  }

  static Future<List<ChartTrack>> getGeoTopTracks(String country, {int limit = 50, int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?method=geo.gettoptracks&country=$country&api_key=$_apiKey&format=json&limit=$limit&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load charts');
    final data = jsonDecode(res.body);
    final tracks = data['tracks']['track'] as List;
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      final images = t['image'] as List;
      final img = images.isNotEmpty ? images.last['#text'] as String : '';
      return ChartTrack(
        rank: (page - 1) * limit + e.key + 1,
        name: t['name'] ?? '',
        artist: t['artist']?['name'] ?? '',
        imageUrl: img,
        playcount: int.tryParse('${t['playcount']}') ?? 0,
        listeners: int.tryParse('${t['listeners']}') ?? 0,
        url: t['url'] ?? '',
      );
    }).toList();
  }

  static Future<List<ChartTrack>> getTagTopTracks(String tag, {int limit = 50, int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?method=tag.gettoptracks&tag=$tag&api_key=$_apiKey&format=json&limit=$limit&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load charts');
    final data = jsonDecode(res.body);
    final tracks = data['tracks']['track'] as List;
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      final images = t['image'] as List;
      final img = images.isNotEmpty ? images.last['#text'] as String : '';
      return ChartTrack(
        rank: (page - 1) * limit + e.key + 1,
        name: t['name'] ?? '',
        artist: t['artist']?['name'] ?? '',
        imageUrl: img,
        playcount: int.tryParse('${t['playcount']}') ?? 0,
        listeners: int.tryParse('${t['listeners']}') ?? 0,
        url: t['url'] ?? '',
      );
    }).toList();
  }

  static Future<List<ChartArtist>> getTagTopArtists(String tag, {int limit = 50, int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?method=tag.gettopartists&tag=$tag&api_key=$_apiKey&format=json&limit=$limit&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load artists');
    final data = jsonDecode(res.body);
    final artists = data['topartists']['artist'] as List;
    return artists.asMap().entries.map((e) {
      final a = e.value;
      final images = a['image'] as List;
      final img = images.isNotEmpty ? images.last['#text'] as String : '';
      return ChartArtist(
        rank: (page - 1) * limit + e.key + 1,
        name: a['name'] ?? '',
        imageUrl: img,
        playcount: int.tryParse('${a['playcount']}') ?? 0,
        listeners: int.tryParse('${a['listeners']}') ?? 0,
        url: a['url'] ?? '',
      );
    }).toList();
  }

  static Future<List<ChartArtist>> getTopArtists({int limit = 50, int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?method=chart.gettopartists&api_key=$_apiKey&format=json&limit=$limit&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load artists');
    final data = jsonDecode(res.body);
    final artists = data['artists']['artist'] as List;
    return artists.asMap().entries.map((e) {
      final a = e.value;
      final images = a['image'] as List;
      final img = images.isNotEmpty ? images.last['#text'] as String : '';
      return ChartArtist(
        rank: (page - 1) * limit + e.key + 1,
        name: a['name'] ?? '',
        imageUrl: img,
        playcount: int.tryParse('${a['playcount']}') ?? 0,
        listeners: int.tryParse('${a['listeners']}') ?? 0,
        url: a['url'] ?? '',
      );
    }).toList();
  }
}
