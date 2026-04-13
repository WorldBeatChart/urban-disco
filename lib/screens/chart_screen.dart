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
  bool _showScrollTop = false;
  bool _showScrollBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onMainScroll);
    _init();
  }

  void _onMainScroll() {
    if (!_scrollCtrl.hasClients) return;
    final top = _scrollCtrl.offset > 200;
    final bottom = _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 200;
    if (top != _showScrollTop || bottom != _showScrollBottom) {
      setState(() { _showScrollTop = top; _showScrollBottom = bottom; });
    }
  }

  @override
  void dispose() { _scrollCtrl.dispose(); _artistCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  Future<void> _init() async {
    try {
      _genres = await DeezerApi.getGenres();
    } catch (_) {}
    if (_genres.isEmpty) {
      _genres = [
        DeezerGenre(id: 0, name: 'All'),
        DeezerGenre(id: 132, name: 'Pop'),
        DeezerGenre(id: 116, name: 'Rap/Hip Hop'),
        DeezerGenre(id: 152, name: 'Rock'),
        DeezerGenre(id: 113, name: 'Dance'),
        DeezerGenre(id: 165, name: 'R&B'),
        DeezerGenre(id: 85, name: 'Alternative'),
        DeezerGenre(id: 106, name: 'Electro'),
        DeezerGenre(id: 466, name: 'Folk'),
        DeezerGenre(id: 464, name: 'Metal'),
        DeezerGenre(id: 129, name: 'Jazz'),
        DeezerGenre(id: 98, name: 'Classical'),
        DeezerGenre(id: 84, name: 'Country'),
        DeezerGenre(id: 144, name: 'Reggae'),
        DeezerGenre(id: 169, name: 'Soul & Funk'),
        DeezerGenre(id: 2, name: 'African'),
        DeezerGenre(id: 16, name: 'Asian'),
        DeezerGenre(id: 75, name: 'Brazilian'),
        DeezerGenre(id: 81, name: 'Indian'),
        DeezerGenre(id: 197, name: 'Latin'),
        DeezerGenre(id: 173, name: 'Films/Games'),
      ];
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
      // Sort by release date, newest first
      _albums.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      _albums = _albums.asMap().entries.map((e) {
        final a = e.value;
        return DeezerAlbum(rank: e.key + 1, title: a.title, artist: a.artist,
          coverMedium: a.coverMedium, coverBig: a.coverBig, url: a.url,
          releaseDate: a.releaseDate, genreId: a.genreId);
      }).toList();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load. Try again.'; _loading = false; });
    }
  }

  void _onArtistChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _artistQuery = v.trim();
      _load();
    });
  }

  void _changeGenre(int id) {
    setState(() => _selectedGenreId = id);
    _load();
  }

  List<DeezerGenre> get _filteredGenres {
    if (_genreSearch.isEmpty) return _genres;
    final q = _genreSearch.toLowerCase();
    final f = _genres.where((g) => g.name.toLowerCase().contains(q)).toList();
    // Always keep "All" (id=0) first
    if (!f.any((g) => g.id == 0)) {
      final all = _genres.where((g) => g.id == 0);
      if (all.isNotEmpty) f.insert(0, all.first);
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final selName = _genres.where((g) => g.id == _selectedGenreId).firstOrNull?.name ?? 'All';
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
            // Hero
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [const Color(0xFFFF1493).withOpacity(0.5), const Color(0xFF1e1b4b)]),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.pexels.com/photos/196652/pexels-photo-196652.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
                    fit: BoxFit.cover, opacity: 0.3),
                ),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.album_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Text('World Beat Chart', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 10),
                  // Artist search
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15))),
                    child: TextField(
                      controller: _artistCtrl,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by artist or album...', hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
                        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                        suffixIcon: _artistCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                              onPressed: () { _artistCtrl.clear(); _artistQuery = ''; _load(); })
                          : null),
                      onSubmitted: (_) => _onArtistChanged(_artistCtrl.text),
                      onChanged: (v) { setState(() {}); _onArtistChanged(v); }),
                  ),
                  const SizedBox(height: 10),
                  // Genre filter
                  _FilterRow(
                    hint: 'Search genre...',
                    onSearch: (v) => setState(() => _genreSearch = v),
                    children: _filteredGenres.map((g) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(label: g.name, sel: _selectedGenreId == g.id, onTap: () => _changeGenre(g.id)),
                    )).toList(),
                  ),
                ]),
              ),
            ),
            // Content
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF818cf8))))
            else if (_error != null)
              SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: GoogleFonts.inter(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry'))])))
            else if (_albums.isEmpty)
              SliverFillRemaining(child: Center(child: Text('No albums found for $selName',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 15))))
            else
              SliverPadding(padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    if (i >= _albums.length) return null;
                    return _AlbumCard(album: _albums[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms)
                        .slideY(begin: 0.05, end: 0);
                  }, childCount: _albums.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
        // Floating scroll buttons
        if (_showScrollTop)
          Positioned(right: 16, bottom: 60, child: _ScrollBtn(
            icon: Icons.keyboard_arrow_up_rounded,
            onTap: () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut))),
        if (_showScrollBottom)
          Positioned(right: 16, bottom: 16, child: _ScrollBtn(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500), curve: Curves.easeOut))),
        ]),
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final DeezerAlbum album;
  const _AlbumCard({required this.album});
  @override State<_AlbumCard> createState() => _AlbumCardState();
}
class _AlbumCardState extends State<_AlbumCard> {
  bool _h = false;
  @override Widget build(BuildContext c) {
    final a = widget.album;
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: () => openUrl(a.url),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          transform: _h ? (Matrix4.identity()..translate(0.0, -4.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _h ? const Color(0xFF1e293b) : const Color(0xFF162032),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _h ? const Color(0xFF6366f1).withOpacity(0.4) : Colors.transparent),
            boxShadow: _h ? [BoxShadow(color: const Color(0xFF6366f1).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: AspectRatio(aspectRatio: 1,
                child: a.coverMedium.isNotEmpty
                  ? Image.network(a.coverBig.isNotEmpty ? a.coverBig : a.coverMedium, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF334155),
                        child: const Icon(Icons.album_rounded, color: Colors.white24, size: 48)))
                  : Container(color: const Color(0xFF334155),
                      child: const Icon(Icons.album_rounded, color: Colors.white24, size: 48)))),
            Expanded(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2)),
                const SizedBox(height: 4),
                Text(a.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                if (a.releaseDate.isNotEmpty) ...[
                  const Spacer(),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(a.releaseDate, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF818cf8)))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => openUrl('https://www.youtube.com/results?search_query=${Uri.encodeComponent('${a.artist} ${a.title} full album')}'),
                      child: Container(padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFFFF0000).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF4444), size: 16))),
                  ]),
                ],
              ]))),
          ]))));
  }
}

class _Chip extends StatefulWidget {
  final String label; final bool sel; final VoidCallback onTap;
  const _Chip({required this.label, required this.sel, required this.onTap});
  @override State<_Chip> createState() => _ChipState();
}
class _ChipState extends State<_Chip> {
  bool _h = false;
  @override Widget build(BuildContext c) => MouseRegion(cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: widget.sel ? const Color(0xFF6366f1).withOpacity(0.2) : _h ? const Color(0xFF334155) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.sel ? const Color(0xFF6366f1) : _h ? const Color(0xFF475569) : const Color(0xFF334155))),
      child: Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
        color: widget.sel ? const Color(0xFF818cf8) : Colors.white70)))));
}

class _FilterRow extends StatefulWidget {
  final String hint; final ValueChanged<String> onSearch; final List<Widget> children;
  const _FilterRow({required this.hint, required this.onSearch, required this.children});
  @override State<_FilterRow> createState() => _FilterRowState();
}
class _FilterRowState extends State<_FilterRow> {
  final _sc = ScrollController();
  final _tc = TextEditingController();
  bool _sl = false, _sr = true;
  @override void initState() { super.initState(); _sc.addListener(_u); WidgetsBinding.instance.addPostFrameCallback((_) => _u()); }
  void _u() { if (!_sc.hasClients) return; setState(() { _sl = _sc.offset > 10; _sr = _sc.offset < _sc.position.maxScrollExtent - 10; }); }
  void _by(double d) { _sc.animateTo((_sc.offset + d).clamp(0.0, _sc.position.maxScrollExtent), duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }
  @override void dispose() { _sc.dispose(); _tc.dispose(); super.dispose(); }
  @override Widget build(BuildContext c) => SizedBox(height: 34, child: Row(children: [
    SizedBox(width: 120, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: TextField(controller: _tc, style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
        decoration: InputDecoration(hintText: widget.hint, hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: const Icon(Icons.search_rounded, size: 14, color: Colors.white38),
          prefixIconConstraints: const BoxConstraints(minWidth: 20)),
        onChanged: (v) { widget.onSearch(v); WidgetsBinding.instance.addPostFrameCallback((_) => _u()); }))),
    const SizedBox(width: 8),
    if (_sl) _Arr(icon: Icons.chevron_left_rounded, onTap: () => _by(-150)),
    Expanded(child: ListView(controller: _sc, scrollDirection: Axis.horizontal, children: widget.children)),
    if (_sr) _Arr(icon: Icons.chevron_right_rounded, onTap: () => _by(150)),
  ]));
}

class _Arr extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _Arr({required this.icon, required this.onTap});
  @override State<_Arr> createState() => _ArrState();
}
class _ArrState extends State<_Arr> {
  bool _h = false;
  @override Widget build(BuildContext c) => MouseRegion(cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      width: 28, height: 28, decoration: BoxDecoration(color: _h ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(widget.icon, color: Colors.white, size: 20))));
}

class _ScrollBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _ScrollBtn({required this.icon, required this.onTap});
  @override State<_ScrollBtn> createState() => _ScrollBtnState();
}
class _ScrollBtnState extends State<_ScrollBtn> {
  bool _h = false;
  @override Widget build(BuildContext c) => MouseRegion(cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: _h ? const Color(0xFF6366f1) : const Color(0xFF1e293b).withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Icon(widget.icon, color: Colors.white, size: 24))));
}
