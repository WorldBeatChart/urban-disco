import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/deezer_api.dart';
import '../utils/url_helper.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<DeezerAlbum> _albums = [];
  List<DeezerGenre> _genres = [];
  bool _loading = true;
  String? _error;
  int _selectedGenreId = 0;
  String _genreSearch = '';
  String _artistQuery = '';
  final _artistCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try { _genres = await DeezerApi.getGenres(); } catch (_) {}
    if (_genres.isEmpty) {
      _genres = [DeezerGenre(id: 0, name: 'All'), DeezerGenre(id: 132, name: 'Pop')];
    }
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_artistQuery.isNotEmpty) {
        _albums = await DeezerApi.searchAlbums(_artistQuery, limit: 100);
      } else {
        _albums = await DeezerApi.getNewReleases(genreId: _selectedGenreId, limit: 100);
      }

      // STROGO SORTIRANJE: Proveravamo da li je datum u formatu YYYY-MM-DD
      _albums.sort((a, b) {
        bool isValid(String d) => d.isNotEmpty && d.contains('-') && d.length >= 8;
        bool vA = isValid(a.releaseDate);
        bool vB = isValid(b.releaseDate);

        if (!vA && vB) return 1;  // Nevalidni na dno
        if (vA && !vB) return -1;
        if (!vA && !vB) return 0;
        return b.releaseDate.compareTo(a.releaseDate); // Najnoviji na vrh
      });

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Error. Pull to refresh.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AlbumDrop v2', // MARKER ZA NOVU VERZIJU
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _artistCtrl,
                        decoration: InputDecoration(hintText: 'Search artist...', filled: true, fillColor: Colors.white10),
                        onChanged: (v) {
                           _debounce?.cancel();
                           _debounce = Timer(const Duration(milliseconds: 500), () {
                             _artistQuery = v; _load();
                           });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.7),
                  delegate: SliverChildBuilderDelegate((c, i) {
                    final a = _albums[i];
                    return GestureDetector(
                      onTap: () => openUrl(a.url),
                      child: Column(
                        children: [
                          Expanded(child: Image.network(a.coverMedium, fit: BoxFit.cover)),
                          Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(a.releaseDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  }, childCount: _albums.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
