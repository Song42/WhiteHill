import 'package:flutter/material.dart';

class AddSongStep1 extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController albumController;
  final TextEditingController bpmController;
  final TextEditingController keyController;

  const AddSongStep1({
    super.key,
    required this.titleController,
    required this.artistController,
    required this.albumController,
    required this.bpmController,
    required this.keyController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Song Info', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Song Title *',
              hintText: 'Enter song title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: artistController,
            decoration: const InputDecoration(
              labelText: 'Artist *',
              hintText: 'Enter artist name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: albumController,
            decoration: const InputDecoration(
              labelText: 'Album',
              hintText: 'Enter album title (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: bpmController,
                  decoration: const InputDecoration(
                    labelText: 'BPM',
                    hintText: 'e.g. 120',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'e.g. C, Am',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
