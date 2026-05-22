import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

class GoLiveScreen extends StatefulWidget {
  final String venueId;

  const GoLiveScreen({super.key, required this.venueId});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  bool _live = false;
  int _viewers = 0;
  Timer? _viewerTimer;
  final _titleController = TextEditingController(text: 'Live from the venue');

  @override
  void dispose() {
    _viewerTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleLive() {
    if (_live) {
      _viewerTimer?.cancel();
      setState(() {
        _live = false;
        _viewers = 0;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live stream ended'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _live = true;
      _viewers = 12;
    });
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_live) return;
      setState(() => _viewers += 1 + (DateTime.now().millisecond % 4));
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(widget.venueId);

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _live ? 'LIVE' : 'Go Live',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _live ? WtvaColors.accentPink : WtvaColors.neutral50,
          ),
        ),
        actions: [
          if (_live)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 16, color: WtvaColors.neutral200),
                    const SizedBox(width: 4),
                    Text('$_viewers', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            detail.venue.imageUrl,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WtvaColors.dark500.withValues(alpha: 0.5),
                  WtvaColors.dark500.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  if (_live)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: WtvaColors.accentPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 6),
                          Text('BROADCASTING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                        ],
                      ),
                    )
                  else
                    Text(
                      detail.venue.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  const SizedBox(height: 12),
                  if (!_live)
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: WtvaColors.neutral50),
                      decoration: const InputDecoration(
                        hintText: 'Stream title',
                        filled: true,
                        fillColor: WtvaColors.dark400,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_live)
                    const Text(
                      'Camera preview — connect device camera in production',
                      style: TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                    ),
                  const SizedBox(height: 24),
                  WtvaGradientButton(
                    label: _live ? 'End live' : 'Start live',
                    onPressed: _toggleLive,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
