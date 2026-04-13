import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../services/lastfm_api.dart';

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
  String _tab = 'songs'; // 'songs' or 'artists'
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == 'songs') {
        final country = _countries[_selectedCountry]!;
        final hasGenre = _selectedGenre != 'All Genres';
        final hasCountry = country.isNotEmpty;
        if (hasGenre && hasCountry) {
          // Fetch both and intersect
          final byGenre = await LastFmApi.getTagTopTracks(_selectedGenre.toLowerCase(), limit: 100);
          final byCountry = await LastFmApi.getGeoTopTracks(country, limit: 100);
          final countryNames = byCountry.map((t) => '${t.name}|${t.artist}'.toLowerCase()).toSet();
          final filtered = byGenre.where((t) => countryNames.contains('${t.name}|${t.artist}'.toLowerCase())).toList();
          _tracks = filtered.asMap().entries.map((e) {
            final t = e.value;
            return ChartTrack(rank: e.key + 1, name: t.name, artist: t.artist, imageUrl: t.imageUrl, playcount: t.playcount, listeners: t.listeners, url: t.url);
          }).toList();
        } else if (hasGenre) {
          _tracks = await LastFmApi.getTagTopTracks(_selectedGenre.toLowerCase(), limit: 100);
        } else if (hasCountry) {
          _tracks = await LastFmApi.getGeoTopTracks(country, limit: 100);
        } else {
          _tracks = await LastFmApi.getTopTracks(limit: 100);
        }
      } else {
        _artists = await LastFmApi.getTopArtists(limit: 100);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load data. Try again.'; _loading = false; });
    }
  }

  void _changeCountry(String country) {
    setState(() => _selectedCountry = country);
    _load();
  }

  void _changeGenre(String genre) {
    setState(() => _selectedGenre = genre);
    _load();
  }

  void _changeTab(String tab) {
    setState(() => _tab = tab);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1e1b4b), Color(0xFF0f172a)],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.music_note_rounded, color: Color(0xFF818cf8), size: 32),
                  const SizedBox(width: 10),
                  Text('World Beat Chart', style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF818cf8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('🔴 LIVE', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF818cf8))),
                  ),
                ]).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 16),
                // Tabs
                Row(children: [
                  _TabButton(label: '🎵 Top Songs', isSelected: _tab == 'songs',
                    onTap: () => _changeTab('songs')),
                  const SizedBox(width: 10),
                  _TabButton(label: '🎤 Top Artists', isSelected: _tab == 'artists',
                    onTap: () => _changeTab('artists')),
                ]),
                if (_tab == 'songs') ...[
                  const SizedBox(height: 12),
                  // Country selector
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _countries.keys.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CountryChip(label: c, isSelected: _selectedCountry == c,
                          onTap: () => _changeCountry(c)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Genre selector
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _genres.map((g) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CountryChip(label: g, isSelected: _selectedGenre == g,
                          onTap: () => _changeGenre(g)),
                      )).toList(),
                    ),
                  ),
                ],
              ]),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF818cf8)))
                  : _error != null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!, style: GoogleFonts.inter(color: Colors.white70)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Retry')),
                        ]))
                      : _tab == 'songs'
                          ? _buildSongsList()
                          : _buildArtistsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final t = _tracks[index];
        return _SongTile(track: t, fmt: _fmt)
            .animate().fadeIn(delay: Duration(milliseconds: index * 30), duration: 300.ms);
      },
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final a = _artists[index];
        return _ArtistTile(artist: a, fmt: _fmt)
            .animate().fadeIn(delay: Duration(milliseconds: index * 30), duration: 300.ms);
      },
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
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFF6366f1) : _hovering ? const Color(0xFF334155) : const Color(0xFF1e293b),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isSelected ? const Color(0xFF6366f1) : const Color(0xFF334155)),
          ),
          child: Text(widget.label, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: widget.isSelected ? Colors.white : _hovering ? Colors.white : Colors.white70)),
        ),
      ),
    );
  }
}

class _CountryChip extends StatefulWidget {
  final String label; final bool isSelected; final VoidCallback onTap;
  const _CountryChip({required this.label, required this.isSelected, required this.onTap});
  @override
  State<_CountryChip> createState() => _CountryChipState();
}

class _CountryChipState extends State<_CountryChip> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFF6366f1).withOpacity(0.2) : _hovering ? const Color(0xFF334155) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.isSelected ? const Color(0xFF6366f1) : _hovering ? const Color(0xFF475569) : const Color(0xFF334155)),
          ),
          child: Text(widget.label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: widget.isSelected ? const Color(0xFF818cf8) : Colors.white70)),
        ),
      ),
    );
  }
}

class _SongTile extends StatefulWidget {
  final ChartTrack track; final NumberFormat fmt;
  const _SongTile({required this.track, required this.fmt});
  @override
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final rankColor = t.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => html.window.open(t.url, '_blank'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          transform: _hovering ? (Matrix4.identity()..translate(4.0, 0.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xFF1e293b) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovering ? const Color(0xFF6366f1).withOpacity(0.3) : Colors.transparent),
          ),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${t.rank}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: t.rank <= 3 ? 20 : 16,
                fontWeight: FontWeight.w800, color: rankColor))),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: t.imageUrl.isNotEmpty
                  ? Image.network(t.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 3),
              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.headphones_rounded, size: 13, color: Color(0xFF818cf8)),
                const SizedBox(width: 4),
                Text(widget.fmt.format(t.listeners), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ]),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF34d399)),
                const SizedBox(width: 4),
                Text(widget.fmt.format(t.playcount), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(width: 50, height: 50,
    decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 22));
}

class _ArtistTile extends StatefulWidget {
  final ChartArtist artist; final NumberFormat fmt;
  const _ArtistTile({required this.artist, required this.fmt});
  @override
  State<_ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends State<_ArtistTile> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    final rankColor = a.rank <= 3 ? const Color(0xFFfbbf24) : Colors.white54;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => html.window.open(a.url, '_blank'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          transform: _hovering ? (Matrix4.identity()..translate(4.0, 0.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xFF1e293b) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovering ? const Color(0xFF6366f1).withOpacity(0.3) : Colors.transparent),
          ),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${a.rank}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: a.rank <= 3 ? 20 : 16,
                fontWeight: FontWeight.w800, color: rankColor))),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: a.imageUrl.isNotEmpty
                  ? Image.network(a.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_rounded, size: 13, color: Color(0xFF818cf8)),
                const SizedBox(width: 4),
                Text(widget.fmt.format(a.listeners), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ]),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF34d399)),
                const SizedBox(width: 4),
                Text(widget.fmt.format(a.playcount), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(width: 50, height: 50,
    decoration: BoxDecoration(color: const Color(0xFF334155), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white38, size: 22));
}
