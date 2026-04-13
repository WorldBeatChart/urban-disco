import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/lastfm_api.dart';
import '../utils/url_helper.dart';

const _countries = {
  'Worldwide': '',
  'Serbia': 'serbia',
  'Croatia': 'croatia',
  'United States': 'united states',
  'United Kingdom': 'united kingdom',
  'Germany': 'germany',
  'France': 'france',
  'Japan': 'japan',
  'Brazil': 'brazil',
  'Spain': 'spain',
  'Italy': 'italy',
  'Canada': 'canada',
  'Australia': 'australia',
  'South Korea': 'south korea',
  'Mexico': 'mexico',
  'Turkey': 'turkey',
  'India': 'india',
};

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
  List<ChartTrack> _tracks = [];
  List<ChartArtist> _artists = [];
  bool _loading = true;
  String? _error;
  String _selectedCountry = 'Worldwide';
  String _selectedGenre = 'All Genres';
  String _selectedOrigin = 'All Origins';
  String _tab = 'songs';
  String _countrySearch = '';
  String _genreSearch = '';
  String _originSearch = '';
  final _fmt = NumberFormat('#,###');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == 'songs') {
        final country = _countries[_selectedCountry] ?? '';
        final hasGenre = _selectedGenre != 'All Genres';
        final hasCountry = country.isNotEmpty;
        final originTag = _origins[_selectedOrigin] ?? '';
        final hasOrigin = originTag.isNotEmpty;

        List<ChartTrack> base;
        if (hasGenre) {
          base = await LastFmApi.getTagTopTracks(_selectedGenre.toLowerCase(), limit: 100);
        } else if (hasCountry) {
          base = await LastFmApi.getGeoTopTracks(country, limit: 100);
        } else {
          base = await LastFmApi.getTopTracks(limit: 100);
        }

        if (hasGenre && hasCountry) {
          final byCountry = await LastFmApi.getGeoTopTracks(country, limit: 100);
          final countryNames = byCountry.map((t) => '${t.name}|${t.artist}'.toLowerCase()).toSet();
          base = base.where((t) => countryNames.contains('${t.name}|${t.artist}'.toLowerCase())).toList();
        }

        if (hasOrigin) {
          final originArtists = await LastFmApi.getTagTopArtists(originTag, limit: 200);
          final artistNames = originArtists.map((a) => a.name.toLowerCase()).toSet();
          base = base.where((t) => artistNames.contains(t.artist.toLowerCase())).toList();
        }

        _tracks = base.asMap().entries.map((e) {
          final t = e.value;
          return ChartTrack(rank: e.key + 1, name: t.name, artist: t.artist, imageUrl: t.imageUrl, playcount: t.playcount, listeners: t.listeners, url: t.url);
        }).toList();
      } else {
        final originTag = _origins[_selectedOrigin] ?? '';
        if (originTag.isNotEmpty) {
          _artists = await LastFmApi.getTagTopArtists(originTag, limit: 100);
        } else {
          _artists = await LastFmApi.getTopArtists(limit: 100);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load data. Try again.'; _loading = false; });
    }
  }

  void _changeCountry(String c) { setState(() => _selectedCountry = c); _load(); }
  void _changeGenre(String g) { setState(() => _selectedGenre = g); _load(); }
  void _changeOrigin(String o) { setState(() => _selectedOrigin = o); _load(); }
  void _changeTab(String t) { setState(() => _tab = t); _load(); }

  List<String> _filteredCountries() {
    final all = _countries.keys.toList();
    if (_countrySearch.isEmpty) return all;
    final q = _countrySearch.toLowerCase();
    final filtered = all.where((c) => c.toLowerCase().contains(q)).toList();
    if (!filtered.contains('Worldwide')) filtered.insert(0, 'Worldwide');
    return filtered;
  }

  List<String> _filteredGenres() {
    if (_genreSearch.isEmpty) return _genres;
    final q = _genreSearch.toLowerCase();
    final filtered = _genres.where((g) => g.toLowerCase().contains(q)).toList();
    if (!filtered.contains('All Genres')) filtered.insert(0, 'All Genres');
    return filtered;
  }

  List<String> _filteredOrigins() {
    final all = _origins.keys.toList();
    if (_originSearch.isEmpty) return all;
    final q = _originSearch.toLowerCase();
    final filtered = all.where((o) => o.toLowerCase().contains(q)).toList();
    if (!filtered.contains('All Origins')) filtered.insert(0, 'All Origins');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Banner
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                      child: Text('🔴 LIVE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ]).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 6),
                  Text('Track the world\'s hottest music', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _TabButton(label: '🎵 Top Songs', isSelected: _tab == 'songs', onTap: () => _changeTab('songs')),
                    const SizedBox(width: 10),
                    _TabButton(label: '🎤 Top Artists', isSelected: _tab == 'artists', onTap: () => _changeTab('artists')),
                  ]),
                  if (_tab == 'songs') ...[
                    const SizedBox(height: 10),
                    _SearchableFilterRow(
                      hint: 'Search country...',
                      onSearch: (v) => setState(() => _countrySearch = v),
                      children: _filteredCountries().map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CountryChip(label: c, isSelected: _selectedCountry == c, onTap: () => _changeCountry(c)),
                      )).toList(),
                    ),
                    const SizedBox(height: 6),
                    _SearchableFilterRow(
                      hint: 'Search genre...',
                      onSearch: (v) => setState(() => _genreSearch = v),
                      children: _filteredGenres().map((g) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CountryChip(label: g, isSelected: _selectedGenre == g, onTap: () => _changeGenre(g)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _SearchableFilterRow(
                    hint: 'Search origin...',
                    onSearch: (v) => setState(() => _originSearch = v),
                    children: _filteredOrigins().map((o) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CountryChip(label: o, isSelected: _selectedOrigin == o, onTap: () => _changeOrigin(o)),
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
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ])))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_tab == 'songs') {
                      if (index >= _tracks.length) return null;
                      return _SongTile(track: _tracks[index], fmt: _fmt)
                          .animate().fadeIn(delay: Duration(milliseconds: index * 30), duration: 300.ms);
                    } else {
                      if (index >= _artists.length) return null;
                      return _ArtistTile(artist: _artists[index], fmt: _fmt)
                          .animate().fadeIn(delay: Duration(milliseconds: index * 30), duration: 300.ms);
                    }
                  },
                  childCount: _tab == 'songs' ? _tracks.length : _artists.length,
                )),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label; final bool isSelected; final VoidCallback onTap;
  const _TabButton({required this.label, required this.isSelected, required this.onTap});
  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected ? const Color(0xFF6366f1) : _h ? const Color(0xFF334155) : const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.isSelected ? const Color(0xFF6366f1) : const Color(0xFF334155))),
        child: Text(widget.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
          color: widget.isSelected ? Colors.white : _h ? Colors.white : Colors.white70)))));
}

class _CountryChip extends StatefulWidget {
  final String label; final bool isSelected; final VoidCallback onTap;
  const _CountryChip({required this.label, required this.isSelected, required this.onTap});
  @override
  State<_CountryChip> createState() => _CountryChipState();
}

class _CountryChipState extends State<_CountryChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected ? const Color(0xFF6366f1).withOpacity(0.2) : _h ? const Color(0xFF334155) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.isSelected ? const Color(0xFF6366f1) : _h ? const Color(0xFF475569) : const Color(0xFF334155))),
        child: Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
          color: widget.isSelected ? const Color(0xFF818cf8) : Colors.white70)))));
}

class _SearchableFilterRow extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSearch;
  final List<Widget> children;
  const _SearchableFilterRow({required this.hint, required this.onSearch, required this.children});
  @override
  State<_SearchableFilterRow> createState() => _SearchableFilterRowState();
}

class _SearchableFilterRowState extends State<_SearchableFilterRow> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    setState(() {
      _showLeft = _scrollCtrl.offset > 10;
      _showRight = _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 10;
    });
  }

  void _scrollBy(double d) {
    _scrollCtrl.animateTo((_scrollCtrl.offset + d).clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(children: [
        // Search field
        SizedBox(width: 120,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hint, hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
                prefixIcon: const Icon(Icons.search_rounded, size: 14, color: Colors.white38),
                prefixIconConstraints: const BoxConstraints(minWidth: 20)),
              onChanged: (v) { widget.onSearch(v); WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll()); }),
          ),
        ),
        const SizedBox(width: 8),
        if (_showLeft) _ArrowBtn(icon: Icons.chevron_left_rounded, onTap: () => _scrollBy(-150)),
        Expanded(child: ListView(controller: _scrollCtrl, scrollDirection: Axis.horizontal, children: widget.children)),
        if (_showRight) _ArrowBtn(icon: Icons.chevron_right_rounded, onTap: () => _scrollBy(150)),
      ]),
    );
  }
}

class _ArrowBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});
  @override
  State<_ArrowBtn> createState() => _ArrowBtnState();
}

class _ArrowBtnState extends State<_ArrowBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 28, height: 28,
        decoration: BoxDecoration(color: _h ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(widget.icon, color: Colors.white, size: 20))));
}

class _SongTile extends StatefulWidget {
  final ChartTrack track; final NumberFormat fmt;
  const _SongTile({required this.track, required this.fmt});
  @override
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final rc = t.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
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
              child: t.imageUrl.isNotEmpty
                ? Image.network(t.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                : _ph()),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 3),
              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.headphones_rounded, size: 13, color: Color(0xFF818cf8)), const SizedBox(width: 4),
                Text(widget.fmt.format(t.listeners), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54))]),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF34d399)), const SizedBox(width: 4),
                Text(widget.fmt.format(t.playcount), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54))]),
            ]),
          ]))));
  }
  Widget _ph() => Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 22));
}

class _ArtistTile extends StatefulWidget {
  final ChartArtist artist; final NumberFormat fmt;
  const _ArtistTile({required this.artist, required this.fmt});
  @override
  State<_ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends State<_ArtistTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    final rc = a.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: () => openUrl(a.url),
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
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_rounded, size: 13, color: Color(0xFF818cf8)), const SizedBox(width: 4),
                Text(widget.fmt.format(a.listeners), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54))]),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF34d399)), const SizedBox(width: 4),
                Text(widget.fmt.format(a.playcount), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54))]),
            ]),
          ]))));
  }
  Widget _ph() => Container(width: 50, height: 50, decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white38, size: 22));
}
