import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../services/deezer_api.dart';
import '../services/lastfm_api.dart';

const _genres = [
  'All Genres', 'Pop', 'Rock', 'Hip-Hop', 'R&B', 'Electronic', 'Dance',
  'Indie', 'Metal', 'Jazz', 'Classical', 'Country', 'Latin', 'K-Pop', 'Reggaeton',
];

const _origins = {
  'All Origins': '',
  '🇷🇸 Serbian': 'serbian',
  '🇭🇷 Croatian': 'croatian',
  '🇧🇦 Bosnian': 'bosnian',
  '🇲🇪 Montenegrin': 'montenegrin',
  '🇲🇰 Macedonian': 'macedonian',
  '🇸🇮 Slovenian': 'slovenian',
  '🇺🇸 American': 'american',
  '🇬🇧 British': 'british',
  '🇩🇪 German': 'german',
  '🇫🇷 French': 'french',
  '🇪🇸 Spanish': 'spanish',
  '🇮🇹 Italian': 'italian',
  '🇧🇷 Brazilian': 'brazilian',
  '🇯🇵 Japanese': 'japanese',
  '🇰🇷 Korean': 'korean',
  '🇹🇷 Turkish': 'turkish',
  '🇮🇳 Indian': 'indian',
};

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<DeezerTrack> _tracks = [];
  List<DeezerArtist> _artists = [];
  bool _loading = true;
  String? _error;
  String _selectedGenre = 'All Genres';
  String _selectedOrigin = 'All Origins';
  String _tab = 'songs';
  String _genreSearch = '';
  String _originSearch = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == 'songs') {
        final hasGenre = _selectedGenre != 'All Genres';
        final originTag = _origins[_selectedOrigin] ?? '';
        final hasOrigin = originTag.isNotEmpty;

        if (!hasGenre && !hasOrigin) {
          // Pure Deezer chart
          _tracks = await DeezerApi.getChart(limit: 100);
        } else if (hasGenre && !hasOrigin) {
          // Search Deezer by genre
          _tracks = await DeezerApi.search(_selectedGenre, limit: 100);
        } else if (hasOrigin && !hasGenre) {
          // Last.fm origin tracks
          final lfmTracks = await LastFmApi.getTagTopTracks(originTag, limit: 1000);
          _tracks = lfmTracks.asMap().entries.map((e) {
            final t = e.value;
            return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist,
              albumCover: t.imageUrl, artistImage: '', url: t.url, duration: 0, preview: '');
          }).toList();
        } else {
          // Genre + Origin: search genre on Deezer, filter by Last.fm origin artists
          var base = await DeezerApi.search(_selectedGenre, limit: 100);
          final originArtists = await LastFmApi.getTagTopArtists(originTag, limit: 1000);
          final artistNames = originArtists.map((a) => a.name.toLowerCase()).toSet();
          final filtered = base.where((t) => artistNames.contains(t.artist.toLowerCase())).toList();
          if (filtered.isNotEmpty) {
            _tracks = filtered.asMap().entries.map((e) {
              final t = e.value;
              return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist,
                albumCover: t.albumCover, artistImage: t.artistImage, url: t.url, duration: t.duration, preview: t.preview);
            }).toList();
          } else {
            // Fallback to origin tracks
            final lfm = await LastFmApi.getTagTopTracks(originTag, limit: 1000);
            _tracks = lfm.asMap().entries.map((e) {
              final t = e.value;
              return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist,
                albumCover: t.imageUrl, artistImage: '', url: t.url, duration: 0, preview: '');
            }).toList();
          }
        }
      } else {
        final originTag = _origins[_selectedOrigin] ?? '';
        if (originTag.isNotEmpty) {
          final lfm = await LastFmApi.getTagTopArtists(originTag, limit: 1000);
          _artists = lfm.asMap().entries.map((e) {
            final a = e.value;
            return DeezerArtist(rank: e.key + 1, name: a.name, imageUrl: a.imageUrl, url: a.url);
          }).toList();
        } else {
          _artists = await DeezerApi.getChartArtists(limit: 100);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load data. Try again.'; _loading = false; });
    }
  }

  void _changeGenre(String g) { setState(() => _selectedGenre = g); _load(); }
  void _changeOrigin(String o) { setState(() => _selectedOrigin = o); _load(); }
  void _changeTab(String t) { setState(() => _tab = t); _load(); }

  List<String> _filteredGenres() {
    if (_genreSearch.isEmpty) return _genres;
    final q = _genreSearch.toLowerCase();
    final f = _genres.where((g) => g.toLowerCase().contains(q)).toList();
    if (!f.contains('All Genres')) f.insert(0, 'All Genres');
    return f;
  }

  List<String> _filteredOrigins() {
    final all = _origins.keys.toList();
    if (_originSearch.isEmpty) return all;
    final q = _originSearch.toLowerCase();
    final f = all.where((o) => o.toLowerCase().contains(q)).toList();
    if (!f.contains('All Origins')) f.insert(0, 'All Origins');
    return f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
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
                    const Icon(Icons.music_note_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Text('World Beat Chart', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2))),
                      child: Text('🔴 LIVE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                  ]).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 6),
                  Text('Track the world\'s hottest music', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _TabBtn(label: '🎵 Top Songs', sel: _tab == 'songs', onTap: () => _changeTab('songs')),
                    const SizedBox(width: 10),
                    _TabBtn(label: '🎤 Top Artists', sel: _tab == 'artists', onTap: () => _changeTab('artists')),
                  ]),
                  if (_tab == 'songs') ...[
                    const SizedBox(height: 10),
                    _FilterRow(hint: 'Search genre...', onSearch: (v) => setState(() => _genreSearch = v),
                      children: _filteredGenres().map((g) => Padding(padding: const EdgeInsets.only(right: 8),
                        child: _Chip(label: g, sel: _selectedGenre == g, onTap: () => _changeGenre(g)))).toList()),
                  ],
                  const SizedBox(height: 6),
                  _FilterRow(hint: 'Search origin...', onSearch: (v) => setState(() => _originSearch = v),
                    children: _filteredOrigins().map((o) => Padding(padding: const EdgeInsets.only(right: 8),
                      child: _Chip(label: o, sel: _selectedOrigin == o, onTap: () => _changeOrigin(o)))).toList()),
                ]),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF818cf8))))
            else if (_error != null)
              SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: GoogleFonts.inter(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry'))])))
            else
              SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(delegate: SliverChildBuilderDelegate((context, i) {
                  if (_tab == 'songs') {
                    if (i >= _tracks.length) return null;
                    return _SongTile(t: _tracks[i]).animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 300.ms);
                  } else {
                    if (i >= _artists.length) return null;
                    return _ArtistTile(a: _artists[i]).animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 300.ms);
                  }
                }, childCount: _tab == 'songs' ? _tracks.length : _artists.length))),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatefulWidget {
  final String label; final bool sel; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.sel, required this.onTap});
  @override State<_TabBtn> createState() => _TabBtnState();
}
class _TabBtnState extends State<_TabBtn> {
  bool _h = false;
  @override Widget build(BuildContext c) => MouseRegion(cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: widget.sel ? const Color(0xFF6366f1) : _h ? const Color(0xFF334155) : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.sel ? const Color(0xFF6366f1) : const Color(0xFF334155))),
      child: Text(widget.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
        color: widget.sel ? Colors.white : _h ? Colors.white : Colors.white70)))));
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

class _SongTile extends StatefulWidget {
  final DeezerTrack t;
  const _SongTile({required this.t});
  @override State<_SongTile> createState() => _SongTileState();
}
class _SongTileState extends State<_SongTile> {
  bool _h = false;
  @override Widget build(BuildContext c) {
    final t = widget.t;
    final rc = t.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    final dur = t.duration > 0 ? '${t.duration ~/ 60}:${(t.duration % 60).toString().padLeft(2, '0')}' : '';
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: () => html.window.open(t.url, '_blank'),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          transform: _h ? (Matrix4.identity()..translate(4.0, 0.0)) : Matrix4.identity(),
          decoration: BoxDecoration(color: _h ? const Color(0xFF1e293b) : Colors.transparent, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _h ? const Color(0xFF6366f1).withOpacity(0.3) : Colors.transparent)),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${t.rank}', textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: t.rank <= 3 ? 20 : 16, fontWeight: FontWeight.w800, color: rc))),
            const SizedBox(width: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: t.albumCover.isNotEmpty
                ? Image.network(t.albumCover, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                : _ph()),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 3),
              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            ])),
            if (dur.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(dur, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
            ],
          ]))));
  }
  Widget _ph() => Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 22));
}

class _ArtistTile extends StatefulWidget {
  final DeezerArtist a;
  const _ArtistTile({required this.a});
  @override State<_ArtistTile> createState() => _ArtistTileState();
}
class _ArtistTileState extends State<_ArtistTile> {
  bool _h = false;
  @override Widget build(BuildContext c) {
    final a = widget.a;
    final rc = a.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: () => html.window.open(a.url, '_blank'),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          transform: _h ? (Matrix4.identity()..translate(4.0, 0.0)) : Matrix4.identity(),
          decoration: BoxDecoration(color: _h ? const Color(0xFF1e293b) : Colors.transparent, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _h ? const Color(0xFF6366f1).withOpacity(0.3) : Colors.transparent)),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${a.rank}', textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: a.rank <= 3 ? 20 : 16, fontWeight: FontWeight.w800, color: rc))),
            const SizedBox(width: 12),
            ClipRRect(borderRadius: BorderRadius.circular(25),
              child: a.imageUrl.isNotEmpty
                ? Image.network(a.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                : _ph()),
            const SizedBox(width: 14),
            Expanded(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
          ]))));
  }
  Widget _ph() => Container(width: 50, height: 50, decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white38, size: 22));
}
