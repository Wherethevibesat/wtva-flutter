import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping background video with a dark scrim for readable UI on top.
class NightlifeVideoBackground extends StatefulWidget {
  final String assetPath;
  final double overlayOpacity;

  const NightlifeVideoBackground({
    super.key,
    this.assetPath = 'assets/videos/mode_picker_bg.mp4',
    this.overlayOpacity = 0.72,
  });

  @override
  State<NightlifeVideoBackground> createState() => _NightlifeVideoBackgroundState();
}

class _NightlifeVideoBackgroundState extends State<NightlifeVideoBackground> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0A0A0A)),
        if (_ready && !_failed)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: widget.overlayOpacity)),
      ],
    );
  }
}
