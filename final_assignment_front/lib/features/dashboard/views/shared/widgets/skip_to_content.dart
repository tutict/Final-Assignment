import 'package:flutter/material.dart';

class SkipToContent extends StatefulWidget {
  const SkipToContent({super.key, required this.target});

  final FocusNode target;

  @override
  State<SkipToContent> createState() => _SkipToContentState();
}

class _SkipToContentState extends State<SkipToContent> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 8,
      top: _visible ? 8 : -56,
      child: Focus(
        onFocusChange: (focused) {
          if (focused != _visible) setState(() => _visible = focused);
        },
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size(88, 40),
          ),
          onPressed: () => widget.target.requestFocus(),
          child: const Text('跳到内容'),
        ),
      ),
    );
  }
}
