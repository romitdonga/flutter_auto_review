import 'package:flutter/material.dart';

/// Simple 5-star fallback dialog. Returns Map with { 'action': 'submit'|'cancel', 'stars': int, 'comment': String? }
class RateUsFallbackDialog extends StatefulWidget {
  const RateUsFallbackDialog({super.key});

  @override
  State<RateUsFallbackDialog> createState() => _RateUsFallbackDialogState();
}

class _RateUsFallbackDialogState extends State<RateUsFallbackDialog> {
  int stars = 5;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enjoying the app?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('If you like the app, please rate us.'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                icon: Icon(idx <= stars ? Icons.star : Icons.star_border),
                onPressed: () => setState(() => stars = idx),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Optional feedback (helps us improve)',
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'action': 'cancel'}),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'action': 'submit',
            'stars': stars,
            'comment': _controller.text,
          }),
          child: const Text('Rate'),
        ),
      ],
    );
  }
}
