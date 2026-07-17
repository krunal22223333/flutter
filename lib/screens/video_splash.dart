import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video splash screen — assets/splash_video.mp4 play karke [next] pe
/// chala jaata hai. Video fail/na load ho to bhi app kabhi atakti nahi:
/// error ya 8s timeout par seedha aage badh jaati hai.
class VideoSplashScreen extends StatefulWidget {
  final Widget next;
  const VideoSplashScreen({super.key, required this.next});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _c;
  bool _navigated = false;
  Timer? _failSafe;

  @override
  void initState() {
    super.initState();
    // Fail-safe: kuch bhi ho jaye, 8 sec me aage
    _failSafe = Timer(const Duration(seconds: 8), _goNext);
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset('assets/splash_video.mp4');
      _c = c;
      await c.initialize();
      c.setVolume(0); // splash muted — store policies ke liye bhi sahi
      c.addListener(_onTick);
      if (!mounted) return;
      setState(() {});
      await c.play();
    } catch (_) {
      _goNext();
    }
  }

  void _onTick() {
    final c = _c;
    if (c == null || _navigated) return;
    final v = c.value;
    if (v.hasError) { _goNext(); return; }
    if (v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 120)) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _failSafe?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _failSafe?.cancel();
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _goNext,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black38,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
