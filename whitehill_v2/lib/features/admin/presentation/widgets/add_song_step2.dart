import 'package:flutter/material.dart';

class AddSongStep2 extends StatelessWidget {
  final TextEditingController lyricsController;

  const AddSongStep2({super.key, required this.lyricsController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lyrics & Chords',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Use ChordPro format: [C]Amazing [G]grace',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lyricsController,
            decoration: const InputDecoration(
              labelText: 'Lyrics with Chords',
              hintText: '[C]Amazing [G]grace how [Am]sweet the sound...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: null,
            minLines: 20,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}
