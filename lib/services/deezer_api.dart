import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://corsproxy.io/?url=https://api.deezer.com';

class DeezerChartArtist {
  final int rank;
  final String name;
  final String imageUrl;
  final String url;
  final String tracklist;

  DeezerChartArtist({required this.rank, required this.name, required this.imageUrl, required this.url, required this.tracklist});
}

class DeezerTrack {
  final int rank;
  final String name;
  final String artist;
  final String albumCover;
  final String url;
  final int duration;
  final String releaseDate;

  DeezerTrack({required this.rank, required this.name, required this.artist, required this.albumCover, required this.url, required this.duration, this.releaseDate = ''});
}

class DeezerApi {
  /// Get top artists for a country chart (1191=Serbia, 63=Croatia)
  static Future<List<DeezerChartArtist>> getChartArtists(int chartId) async {
    final uri = Uri.parse('$_baseUrl/chart/$chartId/artists?limit=100');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed');
    final data = jsonDecode(res.body);
    final list = (data['data'] ?? data['artists']?['data'] ?? []) as List;
    return list.asMap().entries.map((e) {
      final a = e.value;
      return DeezerChartArtist(
        rank: e.key + 1,
        name: a['name'] ?? '',
        imageUrl: a['picture_medium'] ?? '',
        url: a['link'] ?? '',
        tracklist: a['tracklist'] ?? '',
      );
    }).toList();
  }

  /// Get top tracks for a specific artist
  static Future<List<DeezerTrack>> getArtistTopTracks(int artistId, {int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/artist/$artistId/top?limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final list = data['data'] as List;
    return list.map((t) => DeezerTrack(
      rank: 0,
      name: t['title'] ?? '',
      artist: t['artist']?['name'] ?? '',
      albumCover: t['album']?['cover_medium'] ?? '',
      url: t['link'] ?? '',
      duration: t['duration'] ?? 0,
    )).toList();
  }

  /// Build a country top songs list by fetching top artists then their top tracks
  static Future<List<DeezerTrack>> getCountryTopSongs(int chartId) async {
    final uri = Uri.parse('$_baseUrl/chart/$chartId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed');
    final data = jsonDecode(res.body);
    final artists = (data['artists']?['data'] ?? []) as List;

    final tracks = <DeezerTrack>[];
    for (final a in artists.take(30)) {
      final artistId = a['id'] as int;
      final top = await getArtistTopTracks(artistId, limit: 5);
      tracks.addAll(top);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Sort by Deezer rank (popularity) and re-rank
    return tracks.asMap().entries.map((e) {
      final t = e.value;
      return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist, albumCover: t.albumCover, url: t.url, duration: t.duration);
    }).toList();
  }

  /// Get new album releases with their tracks
  static Future<List<DeezerTrack>> getNewReleases({int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/editorial/0/releases?limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed');
    final data = jsonDecode(res.body);
    final albums = data['data'] as List;

    final tracks = <DeezerTrack>[];
    for (final album in albums.take(50)) {
      final tracklist = album['tracklist'] as String?;
      final artistName = album['artist']?['name'] ?? '';
      final cover = album['cover_medium'] ?? '';
      final releaseDate = album['release_date'] ?? '';
      final albumUrl = 'https://www.deezer.com/album/${album['id']}';

      if (tracklist != null && tracklist.isNotEmpty) {
        try {
          final proxyUrl = tracklist.replaceFirst('https://api.deezer.com', _baseUrl);
          final tRes = await http.get(Uri.parse('$proxyUrl?limit=3'));
          if (tRes.statusCode == 200) {
            final tData = jsonDecode(tRes.body);
            final tList = tData['data'] as List;
            for (final t in tList) {
              tracks.add(DeezerTrack(
                rank: 0,
                name: t['title'] ?? album['title'] ?? '',
                artist: artistName,
                albumCover: cover,
                url: t['link'] ?? albumUrl,
                duration: t['duration'] ?? 0,
                releaseDate: releaseDate,
              ));
            }
          }
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return tracks.asMap().entries.map((e) {
      final t = e.value;
      return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist, albumCover: t.albumCover, url: t.url, duration: t.duration, releaseDate: t.releaseDate);
    }).toList();
  }
}
