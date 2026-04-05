import 'package:flutter/material.dart';
import '../widgets/lyrics_section.dart';
import '../widgets/player_section.dart';

class SongDetailScreen extends StatefulWidget {
  final String songId;
  final String title;
  final String artist;
  final String? thumbnailUrl;

  const SongDetailScreen({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
  });

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
            title: widget.title,
            artist: widget.artist,
            thumbnailUrl: widget.thumbnailUrl,
            onScrollToLyrics: _goToLyrics,
          ),
          LyricsSection(
            onScrollToPlayer: _goToPlayer,
          ),
        ],
      ),
    );
  }
}
