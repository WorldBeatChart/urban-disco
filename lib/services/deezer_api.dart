import 'dart:convert';
import 'package:http/http.dart' as http;

// Koristimo corsproxy da bi zaobišli CORS restrikcije u browseru
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

  DeezerAlbum({
    required this.rank, 
    required this.title, 
    required this.artist,
    required this.coverMedium, 
    required this.coverBig, 
    required this.url,
    required this.releaseDate, 
    this.genreId = 0
  });
}

class DeezerGenre {
  final int id;
  final String name;
  DeezerGenre({required this.id, required this.name});
}

class DeezerApi {
  // Funkcija koja dodaje nasumični broj na URL kako bi naterala
  // proksi i browser da uvek vuku najsvežije podatke sa Deezer-a.
  static String _noCache(String url) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}nocache=$now';
  }

  static Future<List<DeezerGenre>> getGenres() async {
    final res = await http.get(Uri.parse(_noCache('$_base/genre')));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return (data['data'] as List)
        .map((g) => DeezerGenre(id: g['id'] ?? 0, name: g['name'] ?? ''))
        .toList();
  }

  static Future<List<DeezerAlbum>> getNewReleases({int genreId = 0, int limit = 100}) async {
    // KORISTIMO CHART ENDPOINT: Brže se osvežava od editorial/releases
    final url = _noCache('$_base/chart/$genreId/albums?limit=$limit');
    final res = await http.get(Uri.parse(url));
    
    if (res.statusCode != 200) throw Exception('Failed to load charts');
    final data = jsonDecode(res.body);
    
    // Deezerov API za liste nekada pakuje podatke direktno u 'data', 
    // a nekada dublje u 'albums' -> 'data'. Ovako pokrivamo oba slučaja.
    final List albums = data['data'] ?? data['albums']?['data'] ?? [];
    
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
    final url = '$_base/search/album?q=${Uri.encodeComponent(query)}&limit=$limit';
    final res = await http.get(Uri.parse(_noCache(url)));
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
        releaseDate: a['release_date'] ?? '', 
        genreId: 0,
      );
    }).toList();
  }

  static Future<List<DeezerAlbum>> getCountryAlbums(int chartId) async {
    final res = await http.get(Uri.parse(_noCache('$_base/chart/$chartId')));
    if (res.statusCode != 200) throw Exception('Failed');
    final data = jsonDecode(res.body);
    final artists = (data['artists']?['data'] ?? []) as List;

    final albums = <DeezerAlbum>[];
    for (final art in artists.take(20)) {
      final artistId = art['id'] as int;
      final artistName = art['name'] ?? '';
      try {
        final aRes = await http.get(Uri.parse(_noCache('$_base/artist/$artistId/albums?limit=5')));
        if (aRes.statusCode == 200) {
          final aData = jsonDecode(aRes.body);
          for (final a in (aData['data'] as List)) {
            albums.add(DeezerAlbum(
              rank: 0,
              title: a['title'] ?? '',
              artist: artistName,
              coverMedium: a['cover_medium'] ?? '',
              coverBig: a['cover_big'] ?? '',
              url: 'https://www.deezer.com/album/${a['id']}',
              releaseDate: a['release_date'] ?? '',
            ));
          }
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return albums;
  }
}
