import 'package:flutter/material.dart';
import '../../data/mock_search_data.dart';
import '../../models/venue.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import 'venue_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Venue> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search([String? q]) {
    final query = q ?? _controller.text;
    setState(() {
      _searched = true;
      _results = MockSearchData.resultsFor(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: const InputDecoration(
            hintText: 'Search venues, tags...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _search()),
        ],
      ),
      body: _searched
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final v = _results[i];
                return WtvaVenueCard(
                  venue: v,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: v.id)),
                  ),
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Recent', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...MockSearchData.recentQueries.map(
                  (q) => ListTile(
                    leading: const Icon(Icons.history, color: WtvaColors.neutral300),
                    title: Text(q),
                    onTap: () {
                      _controller.text = q;
                      _search(q);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
