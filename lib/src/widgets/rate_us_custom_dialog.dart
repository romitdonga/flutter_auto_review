import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../enums/enums.dart';
import '../services/services.dart';

class RateUsCustomDialog extends StatefulWidget {
  final TriggerType triggerType;
  final VoidCallback? onRateSubmitted;
  final VoidCallback? onFeedbackRequested;

  const RateUsCustomDialog({
    super.key,
    required this.triggerType,
    this.onRateSubmitted,
    this.onFeedbackRequested,
  });

  @override
  State<RateUsCustomDialog> createState() => _RateUsCustomDialogState();
}

class _RateUsCustomDialogState extends State<RateUsCustomDialog>
    with SingleTickerProviderStateMixin {
  int _selectedStars = 0;

  File? _riveFile;
  RiveWidgetController? _riveController;
  bool _riveReady = false;

  late final AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      _riveFile = await File.asset(
        'packages/flutter_auto_review/assets/rating.riv',
        riveFactory: Factory.rive,
      );
      _riveController = RiveWidgetController(_riveFile!);
      _riveController?.stateMachine.addEventListener(_onRiveEvent);
      setState(() => _riveReady = true);
    } catch (e) {
      AppLogger.e('Rive load failed: $e');
    }
  }

  void _onRiveEvent(Event event) {
    if (event is GeneralEvent) {
      final rating = int.tryParse(event.name.split('-').last) ?? 0;
      if (rating != _selectedStars) {
        setState(() => _selectedStars = rating);
        _feedbackController.forward(from: 0);
      }
    }
  }

  Color get _accentColor {
    if (_selectedStars >= 4) return const Color(0xFF4CAF50);
    if (_selectedStars > 0) return const Color(0xFFFF9800);
    return Theme.of(context).colorScheme.primary;
  }

  String get _title {
    switch (widget.triggerType) {
      case TriggerType.customEvent:
        return 'Enjoying the experience?';
      case TriggerType.appExit:
        return 'Before you go…';
      default:
        return 'Rate your experience';
    }
  }

  @override
  void dispose() {
    _riveController?.stateMachine.removeEventListener(_onRiveEvent);
    _riveController?.dispose();
    _riveFile?.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF3F0DF),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFFF3F0DF),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(title: _title, accent: _accentColor),
                _RiveRatingBox(
                  riveReady: _riveReady,
                  controller: _riveController,
                  accent: _accentColor,
                ),
                const SizedBox(height: 10),
                _FeedbackSection(
                  stars: _selectedStars,
                  controller: _feedbackController,
                ),
                const SizedBox(height: 14),
                _Actions(
                  stars: _selectedStars,
                  accent: _accentColor,
                  onLater: () => Navigator.pop(context, DialogAction.later),
                  onSubmit: () {
                    widget.onRateSubmitted?.call();
                    Navigator.pop(context, DialogAction.submit);
                  },
                  onFeedback: () {
                    widget.onFeedbackRequested?.call();
                    Navigator.pop(context, DialogAction.dismiss);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final Color accent;

  const _Header({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the stars to rate',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _RiveRatingBox extends StatelessWidget {
  final bool riveReady;
  final RiveWidgetController? controller;
  final Color accent;

  const _RiveRatingBox({
    required this.riveReady,
    required this.controller,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: riveReady && controller != null
              ? ClipRect(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: SizedBox(
                      width: 500,
                      height: 180,
                      child: RiveWidget(
                        controller: controller!,
                        fit: Fit.cover,
                      ),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Container(
          height: 210,
          width: 10,
          decoration: BoxDecoration(color: const Color(0xFFF3F0DF)),
        ),
        Positioned(
          right: 0,
          child: Container(
            height: 210,
            width: 10,
            decoration: BoxDecoration(color: const Color(0xFFF3F0DF)),
          ),
        ),
      ],
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final int stars;
  final AnimationController controller;

  const _FeedbackSection({required this.stars, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (stars == 0) return const SizedBox.shrink();

    final isGood = stars >= 4;

    return FadeTransition(
      opacity: controller,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGood
              ? const Color(0xFF4CAF50).withOpacity(0.12)
              : const Color(0xFFFF9800).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          isGood
              ? 'Awesome! Would you like to rate us on the Play Store?'
              : 'Thanks! Help us improve with your feedback.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isGood ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final int stars;
  final Color accent;
  final VoidCallback onLater;
  final VoidCallback onSubmit;
  final VoidCallback onFeedback;

  const _Actions({
    required this.stars,
    required this.accent,
    required this.onLater,
    required this.onSubmit,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: onLater, child: const Text('Later')),
        const SizedBox(width: 12),
        if (stars > 0)
          FilledButton(
            onPressed: stars >= 3 ? onSubmit : onFeedback,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(stars >= 3 ? 'Rate App' : 'Send Feedback'),
          ),
      ],
    );
  }
}
