import 'package:flutter/material.dart';
import '../../services/customer_portal_api.dart';
import '../../theme/figma_theme.dart';
import 'event_detail_screen.dart';
import 'venue_detail_screen.dart';

class ConciergeSheet {
  ConciergeSheet._();

  static Future<void> show(BuildContext context, {String? initialChip}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ConciergeChatScreen(initialChip: initialChip),
      ),
    );
  }
}

class ConciergeChatScreen extends StatefulWidget {
  const ConciergeChatScreen({super.key, this.initialChip});

  final String? initialChip;

  @override
  State<ConciergeChatScreen> createState() => _ConciergeChatScreenState();
}

class _ChatTurn {
  _ChatTurn({
    required this.id,
    required this.query,
  });

  final String id;
  final String query;
  ConciergeReply? result;
  String? error;
}

class _ConciergeChatScreenState extends State<ConciergeChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_ChatTurn>[];
  late final String _sessionId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sessionId =
        'concierge-${DateTime.now().millisecondsSinceEpoch}-${UniqueKey().hashCode.toRadixString(16)}';
    final chip = widget.initialChip?.trim();
    if (chip != null && chip.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask(chip));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _ask(String raw) async {
    final prompt = raw.trim();
    if (prompt.isEmpty || _busy) return;

    final history = <ConciergeHistoryTurn>[];
    for (final turn in _turns) {
      if (turn.result == null) continue;
      history.add(ConciergeHistoryTurn(role: 'user', content: turn.query));
      history.add(ConciergeHistoryTurn(role: 'assistant', content: turn.result!.reply));
    }

    setState(() {
      _busy = true;
      _turns.add(
        _ChatTurn(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          query: prompt,
        ),
      );
      if (_controller.text.trim() == prompt) _controller.clear();
    });
    _scrollToEnd();

    try {
      final result = await CustomerPortalApi.instance.askConcierge(
        query: prompt,
        sessionId: _sessionId,
        history: history.length > 6 ? history.sublist(history.length - 6) : history,
      );
      if (!mounted) return;
      setState(() {
        _turns.last.result = result;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _turns.last.error =
            e.toString().replaceFirst('Bad state: ', '');
        _busy = false;
      });
    }
    _scrollToEnd();
  }

  void _clear() {
    setState(() {
      _turns.clear();
      _controller.clear();
    });
  }

  void _openRecommendation(ConciergeRecommendation rec) {
    if (rec.id.isEmpty) return;
    if (rec.kind == 'venue') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: rec.id)),
      );
      return;
    }
    // events + event series → event detail when id is a single event
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: rec.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: WtvaColors.accentPurple),
            SizedBox(width: 8),
            Text('Vibes Concierge'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (_busy || (_turns.isEmpty && _controller.text.isEmpty))
                ? null
                : _clear,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (_turns.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WtvaColors.night200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask for a vibe, area, day, or budget and I’ll suggest matching events and venues from what’s live.',
                          style: TextStyle(
                            color: WtvaColors.neutral200,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Example: “rooftop drinks with R&B under \$50 tonight”',
                          style: TextStyle(
                            color: WtvaColors.neutral300,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final turn in _turns) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: WtvaColors.buttonGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        turn.query,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  if (turn.error != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x14EF4444),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x66EF4444)),
                        ),
                        child: Text(
                          turn.error!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (turn.result != null) ...[
                    const SizedBox(height: 8),
                    _AssistantBubble(
                      result: turn.result!,
                      onChip: _busy ? null : _ask,
                      onRec: _openRecommendation,
                    ),
                  ],
                ],
                if (_busy) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Concierge is thinking…',
                    style: TextStyle(
                      color: WtvaColors.neutral300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
            decoration: const BoxDecoration(
              color: WtvaColors.dark400,
              border: Border(top: BorderSide(color: WtvaColors.night200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _busy ? null : _ask,
                    decoration: const InputDecoration(
                      hintText: 'Tell me what vibe you want…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: IconButton(
                    onPressed: _busy
                        ? null
                        : () => _ask(_controller.text),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    required this.result,
    required this.onRec,
    this.onChip,
  });

  final ConciergeReply result;
  final ValueChanged<ConciergeRecommendation> onRec;
  final ValueChanged<String>? onChip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WtvaColors.night200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.reply.trim().isNotEmpty)
              Text(
                result.reply,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: WtvaColors.neutral50,
                ),
              ),
            if (result.clarificationQuestion != null &&
                result.clarificationQuestion!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                result.clarificationQuestion!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: WtvaColors.neutral300,
                ),
              ),
            ],
            if (result.suggestedChips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final chip in result.suggestedChips.take(5))
                    ActionChip(
                      label: Text(chip, style: const TextStyle(fontSize: 12)),
                      onPressed: onChip == null ? null : () => onChip!(chip),
                      backgroundColor: WtvaColors.dark500,
                      side: const BorderSide(color: WtvaColors.night200),
                    ),
                ],
              ),
            ],
            for (final rec in result.recommendations) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => onRec(rec),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WtvaColors.night200),
                    color: WtvaColors.dark500,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.kind.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: WtvaColors.neutral300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (rec.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          rec.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: WtvaColors.neutral200,
                          ),
                        ),
                      ],
                      if (rec.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rec.reason,
                          style: const TextStyle(
                            fontSize: 12,
                            color: WtvaColors.neutral300,
                          ),
                        ),
                      ],
                      if (rec.priceHint != null &&
                          rec.priceHint!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rec.priceHint!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.accentPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
