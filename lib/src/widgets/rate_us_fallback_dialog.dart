import 'package:flutter/material.dart';

/// A fallback dialog that is shown when the native review dialog fails
class RateUsFallbackDialog extends StatelessWidget {
  /// Creates a new RateUsFallbackDialog
  const RateUsFallbackDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Our App'),
      content: const Text(
        'If you enjoy using our app, would you mind taking a moment to rate it? '
        'It won\'t take more than a minute. Thanks for your support!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe Later'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Rate Now'),
        ),
      ],
    );
  }
}
