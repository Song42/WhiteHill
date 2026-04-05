import 'package:flutter/material.dart';

import '../../../songs/domain/entities/song.dart';
import '../widgets/lyrics_section.dart';
import '../widgets/player_section.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  final int initialPage;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.initialPage = 0,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late final _pageController = PageController(initialPage: widget.initialPage);

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
            song: widget.song,
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
