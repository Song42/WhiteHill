import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/add_song_provider.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/artist_album_lookup_provider.dart';

class AddSongStep1 extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController albumController;
  final TextEditingController bpmController;
  final TextEditingController keyController;
  final String? titleError;
  final VoidCallback? onTitleChanged;
  final String? artistError;
  final VoidCallback? onArtistChanged;

  const AddSongStep1({
    super.key,
    required this.titleController,
    required this.artistController,
    required this.albumController,
    required this.bpmController,
    required this.keyController,
    this.titleError,
    this.onTitleChanged,
    this.artistError,
    this.onArtistChanged,
  });

  @override
  ConsumerState<AddSongStep1> createState() => _AddSongStep1State();
}

class _AddSongStep1State extends ConsumerState<AddSongStep1> {
  final _artistFocusNode = FocusNode();
  final _albumFocusNode = FocusNode();
  final _albumLayerLink = LayerLink();
  OverlayEntry? _albumOverlay;

  @override
  void initState() {
    super.initState();
    _artistFocusNode.addListener(_onArtistFocus);
    _albumFocusNode.addListener(_onAlbumFocusChanged);
    widget.albumController.addListener(_onAlbumTextChanged);
  }

  void _onArtistFocus() {
    if (_artistFocusNode.hasFocus) _pingController(widget.artistController);
  }

  /// Sends a zero-delta value change so RawAutocomplete re-evaluates options.
  void _pingController(TextEditingController ctrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final saved = ctrl.value;
      ctrl.value = saved == TextEditingValue.empty
          ? const TextEditingValue(text: ' ')
          : TextEditingValue.empty;
      ctrl.value = saved;
    });
  }

  // ── Album overlay management ──

  void _onAlbumFocusChanged() {
    if (_albumFocusNode.hasFocus) {
      _showAlbumOverlay();
    } else {
      _hideAlbumOverlay();
    }
  }

  void _onAlbumTextChanged() {
    // Rebuild the overlay to reflect filtered results.
    _albumOverlay?.markNeedsBuild();
  }

  void _showAlbumOverlay() {
    _hideAlbumOverlay();
    _albumOverlay = OverlayEntry(builder: (_) => _buildAlbumOverlay());
    Overlay.of(context).insert(_albumOverlay!);
  }

  void _hideAlbumOverlay() {
    _albumOverlay?.remove();
    _albumOverlay = null;
  }

  Widget _buildAlbumOverlay() {
    final selectedArtistId = ref.read(addSongFormProvider).selectedArtistId;
    final albums = selectedArtistId != null
        ? ref.read(albumsByArtistProvider(selectedArtistId)).valueOrNull ?? []
        : <AlbumOption>[];

    final q = widget.albumController.text.toLowerCase();
    final filtered = q.isEmpty
        ? albums
        : albums.where((a) => a.title.toLowerCase().contains(q)).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(addSongFormProvider.notifier);

    final targetContext = _albumFocusNode.context;
    final renderBox = targetContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;

    return CompositedTransformFollower(
      link: _albumLayerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final album = filtered[index];
                return InkWell(
                  onTap: () {
                    widget.albumController.text = album.title;
                    notifier.selectAlbum(album.id, album.coverUrl);
                    _albumFocusNode.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(album.title),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideAlbumOverlay();
    _artistFocusNode.removeListener(_onArtistFocus);
    _albumFocusNode.removeListener(_onAlbumFocusChanged);
    widget.albumController.removeListener(_onAlbumTextChanged);
    _artistFocusNode.dispose();
    _albumFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(addSongFormProvider.notifier);
    final formState = ref.watch(addSongFormProvider);
    final selectedArtistId = formState.selectedArtistId;

    final artists = ref.watch(allArtistsProvider).valueOrNull ?? [];
    // Keep watching so the provider stays alive (no re-fetch).
    final albums = selectedArtistId != null
        ? ref
                .watch(albumsByArtistProvider(selectedArtistId))
                .valueOrNull ??
            []
        : <AlbumOption>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Song Info', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(
            controller: widget.titleController,
            onChanged: (_) => widget.onTitleChanged?.call(),
            decoration: InputDecoration(
              labelText: 'Song Title *',
              hintText: 'Enter song title',
              border: const OutlineInputBorder(),
              errorText: widget.titleError,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _buildArtistField(context, artists, notifier),
          const SizedBox(height: 16),
          _buildAlbumField(context, albums, selectedArtistId, notifier),
          if (formState.existingCoverUrl != null) ...[
            const SizedBox(height: 12),
            _buildAlbumCoverCard(
              context,
              formState.existingCoverUrl!,
              widget.albumController.text,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.bpmController,
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
                  controller: widget.keyController,
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

  Widget _buildAlbumCoverCard(
    BuildContext context,
    String coverUrl,
    String albumTitle,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: coverUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            placeholder: (_, _) => const SizedBox(
              width: 64,
              height: 64,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => const SizedBox(
              width: 64,
              height: 64,
              child: Icon(Icons.album, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              albumTitle,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildArtistField(
    BuildContext context,
    List<ArtistOption> artists,
    AddSongNotifier notifier,
  ) {
    return RawAutocomplete<ArtistOption>(
      textEditingController: widget.artistController,
      focusNode: _artistFocusNode,
      optionsBuilder: (value) {
        final q = value.text.toLowerCase();
        if (q.isEmpty) return artists;
        return artists.where((a) => a.name.toLowerCase().contains(q));
      },
      displayStringForOption: (o) => o.name,
      onSelected: (o) {
        widget.artistController.text = o.name;
        widget.albumController.clear();
        notifier.selectArtist(o.id);
      },
      fieldViewBuilder: (context, ctrl, fn, onFieldSubmitted) {
        return TextField(
          controller: ctrl,
          focusNode: fn,
          onChanged: (_) {
            widget.onArtistChanged?.call();
            widget.albumController.clear();
            // Only rebuild once when transitioning away from a selection.
            if (ref.read(addSongFormProvider).selectedArtistId != null) {
              notifier.clearArtist();
            }
          },
          decoration: InputDecoration(
            labelText: 'Artist *',
            hintText:
                artists.isEmpty ? 'Enter artist name' : 'Search or create new',
            border: const OutlineInputBorder(),
            errorText: widget.artistError,
            suffixIcon:
                artists.isNotEmpty ? const Icon(Icons.arrow_drop_down) : null,
          ),
          textCapitalization: TextCapitalization.words,
        );
      },
      optionsViewBuilder: (context, onSelected, options) =>
          _OptionsOverlay<ArtistOption>(
        options: options,
        labelFor: (o) => o.name,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildAlbumField(
    BuildContext context,
    List<AlbumOption> albums,
    String? selectedArtistId,
    AddSongNotifier notifier,
  ) {
    return CompositedTransformTarget(
      link: _albumLayerLink,
      child: TextField(
        controller: widget.albumController,
        focusNode: _albumFocusNode,
        onChanged: (_) {
          if (ref.read(addSongFormProvider).selectedAlbumId != null) {
            notifier.clearAlbum();
          }
        },
        decoration: InputDecoration(
          labelText: 'Album',
          hintText: selectedArtistId != null && albums.isNotEmpty
              ? 'Search or create new'
              : 'Enter album title (optional)',
          border: const OutlineInputBorder(),
          suffixIcon:
              albums.isNotEmpty ? const Icon(Icons.arrow_drop_down) : null,
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

class _OptionsOverlay<T> extends StatelessWidget {
  final Iterable<T> options;
  final String Function(T) labelFor;
  final void Function(T) onSelected;

  const _OptionsOverlay({
    required this.options,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(labelFor(option)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
