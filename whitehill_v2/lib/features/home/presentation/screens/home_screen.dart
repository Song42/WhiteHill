import 'package:flutter/material.dart';
import 'package:whitehill_v2/features/home/presentation/widgets/song_card.dart';
import 'package:whitehill_v2/features/song_detail/presentation/screens/song_detail_screen.dart';

// Temporary placeholder until real data layer is wired up.
class _MockSong {
  final String id;
  final String title;
  final String artist;

  const _MockSong({
    required this.id,
    required this.title,
    required this.artist,
  });
}

const _mockSongs = [
  _MockSong(id: '1', title: '주 나의 모든 것', artist: '어노인팅'),
  _MockSong(id: '2', title: '내 삶의 이유 돼', artist: '마커스'),
  _MockSong(id: '3', title: 'Way Maker', artist: 'Sinach'),
  _MockSong(id: '4', title: '주님 곁으로', artist: '어노인팅'),
  _MockSong(id: '5', title: 'Oceans', artist: 'Hillsong UNITED'),
  _MockSong(id: '6', title: '사랑해요 목숨 다해', artist: '마커스'),
  _MockSong(id: '7', title: 'Reckless Love', artist: 'Cory Asbury'),
  _MockSong(id: '8', title: '주 품에 품으소서', artist: '어노인팅'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text(
            'WhiteHill',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          sliver: SliverList.builder(
            itemCount: _mockSongs.length,
            itemBuilder: (context, index) {
              final song = _mockSongs[index];
              return SongCard(
                id: song.id,
                title: song.title,
                artist: song.artist,
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => SongDetailScreen(
                      songId: song.id,
                      title: song.title,
                      artist: song.artist,
                    ),
                    transitionsBuilder: (_, animation, _, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
