// import 'package:flutter/material.dart';

// import '../enums/enums.dart';

// class RateUsCustomDialog extends StatefulWidget {
//   final TriggerType triggerType;

//   const RateUsCustomDialog({super.key, required this.triggerType});

//   @override
//   State<RateUsCustomDialog> createState() => _RateUsCustomDialogState();
// }

// class _RateUsCustomDialogState extends State<RateUsCustomDialog> {
//   int _selectedStars = 0;

//   String get _contextualMessage {
//     switch (widget.triggerType) {
//       case TriggerType.customEvent:
//         return '🎉 Great job! Enjoying the app?';
//       case TriggerType.manual:
//         return '⭐ We\'d love to hear from you!';
//       case TriggerType.appExit:
//         return '👋 Before you go, rate us?';
//       default:
//         return '💙 Loving the app?';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       contentPadding: const EdgeInsets.all(24),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             _contextualMessage,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Tap the stars to rate',
//             style: TextStyle(fontSize: 14, color: Colors.grey),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           _buildStarRating(),
//           const SizedBox(height: 24),
//           if (_selectedStars >= 4) _buildHighRatingMessage(),
//           if (_selectedStars > 0 && _selectedStars < 4)
//             _buildLowRatingMessage(),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(DialogAction.later),
//           child: const Text('Later'),
//         ),
//         if (_selectedStars >= 4)
//           FilledButton(
//             onPressed: () => Navigator.of(context).pop(DialogAction.submit),
//             child: const Text('Rate on Play Store'),
//           ),
//         if (_selectedStars > 0 && _selectedStars < 4)
//           FilledButton(
//             onPressed: () => Navigator.of(context).pop(DialogAction.dismiss),
//             child: const Text('Send Feedback'),
//           ),
//       ],
//     );
//   }

//   Widget _buildStarRating() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(5, (index) {
//         final starNumber = index + 1;
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _selectedStars = starNumber;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Icon(
//               starNumber <= _selectedStars ? Icons.star : Icons.star_border,
//               size: 40,
//               color: starNumber <= _selectedStars ? Colors.amber : Colors.grey,
//             ),
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildHighRatingMessage() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.celebration, color: Colors.green),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Awesome! Share your love on the Play Store!',
//               style: TextStyle(
//                 color: Colors.green,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLowRatingMessage() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.feedback_outlined, color: Colors.orange),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Help us improve! Share your feedback.',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../enums/enums.dart';

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
  late AnimationController _feedbackAnimController;
  bool _isRiveLoaded = false;

  @override
  void initState() {
    super.initState();
    _initRiveAnimation();
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _initRiveAnimation() async {
    try {
      _riveFile = await File.asset(
        'packages/flutter_auto_review/assets/rating.riv',
        riveFactory: Factory.rive,
      );

      _riveController = RiveWidgetController(_riveFile!);
      _riveController?.stateMachine.addEventListener(_onRiveEvent);

      setState(() => _isRiveLoaded = true);
    } catch (e) {
      debugPrint('Error loading Rive animation: $e');
      // Fallback to native stars if Rive fails
      setState(() => _isRiveLoaded = false);
    }
  }

  void _onRiveEvent(Event event) {
    final rating = event.numberProperty('rating')?.value.toInt() ?? 0;
    if (rating != _selectedStars) {
      setState(() => _selectedStars = rating);
      _triggerFeedbackAnimation();
    }
  }

  void _triggerFeedbackAnimation() {
    _feedbackAnimController.forward(from: 0);
  }

  String get _contextualMessage {
    switch (widget.triggerType) {
      case TriggerType.customEvent:
        return '🎉 Great job! Enjoying the app?';
      case TriggerType.manual:
        return '⭐ We\'d love to hear from you!';
      case TriggerType.appExit:
        return '👋 Before you go, rate us?';
      default:
        return '💙 Loving the app?';
    }
  }

  Color get _primaryColor {
    return _selectedStars >= 4
        ? const Color(0xFF4CAF50)
        : _selectedStars > 0
        ? const Color(0xFFFF9800)
        : Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    _riveController?.stateMachine.removeEventListener(_onRiveEvent);
    _riveController?.stateMachine.dispose();
    _riveFile?.dispose();
    _riveController?.dispose();
    _feedbackAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [_buildBackgroundDecoration(), _buildMainContent(context)],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [_primaryColor.withOpacity(0.08), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildRiveStarRating(),
          const SizedBox(height: 28),
          _buildFeedbackSection(),
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _contextualMessage,
            key: ValueKey(_selectedStars),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _selectedStars == 0
              ? 'Tap the stars to rate your experience'
              : 'You rated $_selectedStars star${_selectedStars > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRiveStarRating() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 2),
      ),
      child: _isRiveLoaded && _riveFile != null
          ? RiveWidget(controller: _riveController!, fit: Fit.cover)
          : _buildFallbackStarRating(),
    );
  }

  Widget _buildFallbackStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedStars = starNumber);
            _triggerFeedbackAnimation();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedScale(
              scale: starNumber <= _selectedStars ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                starNumber <= _selectedStars ? Icons.star : Icons.star_border,
                size: 44,
                color: starNumber <= _selectedStars
                    ? Colors.amber[600]
                    : Colors.grey[400],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _selectedStars > 0
          ? FadeTransition(
              opacity: _feedbackAnimController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _feedbackAnimController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: _selectedStars >= 4
                    ? _buildHighRatingMessage()
                    : _buildLowRatingMessage(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHighRatingMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.15),
            const Color(0xFF66BB6A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Awesome! Share your love on the Play Store!',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowRatingMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800).withOpacity(0.15),
            const Color(0xFFFFB74D).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.feedback_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Help us improve! Share your feedback.',
              style: TextStyle(
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(DialogAction.later),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Later',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_selectedStars >= 4) _buildPrimaryButton(context, true),
        if (_selectedStars > 0 && _selectedStars < 4)
          _buildPrimaryButton(context, false),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, bool isHighRating) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: FilledButton.icon(
        onPressed: () {
          if (isHighRating) {
            widget.onRateSubmitted?.call();
            Navigator.of(context).pop(DialogAction.submit);
          } else {
            widget.onFeedbackRequested?.call();
            Navigator.of(context).pop(DialogAction.dismiss);
          }
        },
        icon: Icon(
          isHighRating ? Icons.launch_rounded : Icons.edit_rounded,
          size: 18,
        ),
        label: Text(
          isHighRating ? 'Rate on Play Store' : 'Send Feedback',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }
}
