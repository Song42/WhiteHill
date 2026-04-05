import 'package:flutter/material.dart';
import 'package:whitehill_v2/features/songs/domain/entities/song.dart';
import '../widgets/lyrics_section.dart';
import '../widgets/player_section.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final _pageController = PageController();

  void _goToLyrics() => _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  void _goToPlayer() => _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          PlayerSection(
            title: widget.song.title,
            artist: widget.song.artistName ?? '',
            thumbnailUrl: widget.song.coverUrl,
            onScrollToLyrics: _goToLyrics,
          ),
          LyricsSection(
            lyricsChord: widget.song.lyricsChord,
            onScrollToPlayer: _goToPlayer,
          ),
        ],
      ),
    );
  }
}
