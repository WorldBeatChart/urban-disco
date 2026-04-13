import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/deezer_api.dart';
import '../services/lastfm_api.dart';
import '../utils/url_helper.dart';

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
  bool _loading = true;
  String? _error;
  String _selectedGenre = 'All Genres';
  String _selectedOrigin = 'All Origins';
  String _genreSearch = '';
  String _originSearch = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Always fetch new releases from Deezer
      var base = await DeezerApi.getNewReleases(limit: 100);

      final hasGenre = _selectedGenre != 'All Genres';
      final originTag = _origins[_selectedOrigin] ?? '';
      final hasOrigin = originTag.isNotEmpty;

      // Filter by genre using Deezer search
      if (hasGenre) {
        final genreQ = _selectedGenre.toLowerCase();
        base = base.where((t) =>
          t.name.toLowerCase().contains(genreQ) ||
          t.artist.toLowerCase().contains(genreQ)).toList();
        // If local filter gives nothing, search Deezer for genre + "new"
        if (base.isEmpty) {
          final searched = await DeezerApi.search('${_selectedGenre} new 2026', limit: 100);
          base = searched;
        }
      }

      // Filter by origin using Last.fm artist tags
      if (hasOrigin) {
        final originArtists = await LastFmApi.getTagTopArtists(originTag, limit: 1000);
        final artistNames = originArtists.map((a) => a.name.toLowerCase()).toSet();
        final filtered = base.where((t) => artistNames.contains(t.artist.toLowerCase())).toList();
        if (filtered.isNotEmpty) {
          base = filtered;
        } else {
          // Fallback: get origin tracks from Last.fm
          final lfm = await LastFmApi.getTagTopTracks(originTag, limit: 200);
          base = lfm.asMap().entries.map((e) {
            final t = e.value;
            return DeezerTrack(rank: 0, name: t.name, artist: t.artist,
              albumCover: t.imageUrl, url: t.url, duration: 0, releaseDate: '');
          }).toList();
        }
      }

      // Re-rank
      _tracks = base.asMap().entries.map((e) {
        final t = e.value;
        return DeezerTrack(rank: e.key + 1, name: t.name, artist: t.artist,
          albumCover: t.albumCover, url: t.url, duration: t.duration, releaseDate: t.releaseDate);
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load data. Try again.'; _loading = false; });
    }
  }

  void _changeGenre(String g) { setState(() => _selectedGenre = g); _load(); }
  void _changeOrigin(String o) { setState(() => _selectedOrigin = o); _load(); }

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
                      child: Text('🆕 NEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                  ]).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 6),
                  Text('Latest music releases worldwide', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 14),
                  _FilterRow(hint: 'Search genre...', onSearch: (v) => setState(() => _genreSearch = v),
                    children: _filteredGenres().map((g) => Padding(padding: const EdgeInsets.only(right: 8),
                      child: _Chip(label: g, sel: _selectedGenre == g, onTap: () => _changeGenre(g)))).toList()),
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
                  if (i >= _tracks.length) return null;
                  final t = _tracks[i];
                  return _TrackTile(t: t).animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 300.ms);
                }, childCount: _tracks.length))),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
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

class _TrackTile extends StatefulWidget {
  final DeezerTrack t;
  const _TrackTile({required this.t});
  @override State<_TrackTile> createState() => _TrackTileState();
}
class _TrackTileState extends State<_TrackTile> {
  bool _h = false;
  @override Widget build(BuildContext c) {
    final t = widget.t;
    final rc = t.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    final dur = t.duration > 0 ? '${t.duration ~/ 60}:${(t.duration % 60).toString().padLeft(2, '0')}' : '';
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: () => openUrl(t.url),
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
                ? Image.network(t.albumCover, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ph())
                : _ph()),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 3),
              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            ])),
            if (dur.isNotEmpty) ...[const SizedBox(width: 8),
              Text(dur, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38))],
            if (t.releaseDate.isNotEmpty) ...[const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF6366f1).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(t.releaseDate, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF818cf8))))],
          ]))));
  }
  Widget _ph() => Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 22));
}
