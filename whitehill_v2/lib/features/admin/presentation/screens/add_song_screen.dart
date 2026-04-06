import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/add_song_provider.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/artist_album_lookup_provider.dart';
import 'package:whitehill_v2/features/admin/presentation/widgets/add_song_step1.dart';
import 'package:whitehill_v2/features/admin/presentation/widgets/add_song_step2.dart';
import 'package:whitehill_v2/features/admin/presentation/widgets/add_song_step3.dart';
import 'package:whitehill_v2/features/admin/presentation/widgets/add_song_step4.dart';
import 'package:whitehill_v2/features/admin/presentation/widgets/step_indicator.dart';

const _stepLabels = ['Info', 'Lyrics', 'Files', 'Preview'];

class AddSongScreen extends ConsumerStatefulWidget {
  const AddSongScreen({super.key});

  @override
  ConsumerState<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends ConsumerState<AddSongScreen> {
  final _pageController = PageController();

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _albumCtrl = TextEditingController();
  final _bpmCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();

  String? _titleError;
  String? _artistError;

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _lyricsCtrl.dispose();
    super.dispose();
  }

  void _saveCurrentStep(int step) {
    final notifier = ref.read(addSongFormProvider.notifier);
    if (step == 0) {
      notifier.saveStep1(
        title: _titleCtrl.text.trim(),
        artistName: _artistCtrl.text.trim(),
        albumTitle: _albumCtrl.text.trim(),
        bpm: _bpmCtrl.text.trim(),
        songKey: _keyCtrl.text.trim(),
      );
    } else if (step == 1) {
      notifier.saveStep2(lyricsChord: _lyricsCtrl.text);
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      final titleEmpty = _titleCtrl.text.trim().isEmpty;
      final artistEmpty = _artistCtrl.text.trim().isEmpty;
      if (titleEmpty || artistEmpty) {
        setState(() {
          if (titleEmpty) _titleError = 'Required';
          if (artistEmpty) _artistError = 'Required';
        });
        return false;
      }
    }
    return true;
  }

  Future<void> _next() async {
    final currentStep = ref.read(addSongFormProvider).currentStep;
    if (!_validateStep(currentStep)) return;

    if (currentStep == 0) {
      final formState = ref.read(addSongFormProvider);
      final exists = await checkSongTitleExists(
        title: _titleCtrl.text.trim(),
        artistName: _artistCtrl.text.trim(),
        albumTitle: _albumCtrl.text.trim(),
        artistId: formState.selectedArtistId,
        albumId: formState.selectedAlbumId,
      );
      if (!mounted) return;
      if (exists) {
        setState(() => _titleError =
            'This title already exists for the selected artist / album');
        return;
      }
    }

    _saveCurrentStep(currentStep);
    FocusScope.of(context).unfocus();
    ref.read(addSongFormProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    ref.read(addSongFormProvider.notifier).previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(addSongFormProvider.notifier)
          .submit()
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      if (!mounted) return;
      ref.read(addSongFormProvider.notifier).cancelSubmit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload timed out — please try again')),
      );
      return;
    }
    if (!mounted) return;
    final error = ref.read(addSongFormProvider).submissionError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(addSongFormProvider);
    final currentStep = formState.currentStep;
    final isSubmitting = formState.isSubmitting;

    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Add New Song'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !isSubmitting,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: StepIndicator(
              currentStep: currentStep,
              totalSteps: 4,
              labels: _stepLabels,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AddSongStep1(
                  titleController: _titleCtrl,
                  artistController: _artistCtrl,
                  albumController: _albumCtrl,
                  bpmController: _bpmCtrl,
                  keyController: _keyCtrl,
                  titleError: _titleError,
                  onTitleChanged: () => setState(() => _titleError = null),
                  artistError: _artistError,
                  onArtistChanged: () => setState(() => _artistError = null),
                ),
                AddSongStep2(lyricsController: _lyricsCtrl),
                const AddSongStep3(),
                const AddSongStep4(),
              ],
            ),
          ),
          _StepNavBar(
            currentStep: currentStep,
            onBack: currentStep > 0 && !isSubmitting ? _back : null,
            onNext: currentStep == 3 ? _submit : _next,
            isLastStep: currentStep == 3,
            isSubmitting: isSubmitting,
          ),
        ],
        ),
      ),
      ),
    );
  }
}

class _StepNavBar extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLastStep;
  final bool isSubmitting;

  const _StepNavBar({
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.isLastStep,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: onBack != null ? 2 : 1,
              child: FilledButton(
                onPressed: isSubmitting ? null : onNext,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLastStep ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
