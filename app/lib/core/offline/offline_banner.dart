import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a slim banner when the app considers itself offline.
///
/// Production: wire [Connectivity] from `connectivity_plus` (or platform
/// reachability) and replace the stub timer below. Firebase and API base URL
/// configuration are unrelated but should be set before shipping.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.child,
    this.checkInterval = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration checkInterval;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Stub: periodic no-op check. Replace with connectivity_plus stream listener.
    _timer = Timer.periodic(widget.checkInterval, (_) {
      if (mounted && _offline) {
        setState(() => _offline = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Stub hook for tests or future connectivity integration.
  @visibleForTesting
  void setOfflineForTest(bool value) {
    setState(() => _offline = value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _offline ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: MaterialBanner(
            content: const Text(
              'You appear to be offline. Some actions may be queued.',
            ),
            leading: const Icon(Icons.cloud_off_outlined),
            actions: [
              TextButton(
                onPressed: () => setState(() => _offline = false),
                child: const Text('Dismiss'),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
