import 'package:flutter/material.dart';
import '../../../models/business/business_models.dart';
import '../../../services/business_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/business/business_widgets.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';
import 'business_booking_flow.dart';

/// #04 Browse users + filters.
class BusinessBrowseScreen extends StatelessWidget {
  const BusinessBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusinessService.instance,
      builder: (context, _) {
        final svc = BusinessService.instance;
        return FutureBuilder<List<BusinessTalentProfile>>(
          future: svc.filteredTalent(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Browse users',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessBrowseFiltersScreen()),
                  ),
                  icon: const Icon(Icons.tune, color: WtvaColors.neutral200),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Find ranked guests to invite and book.',
              style: TextStyle(color: WtvaColors.neutral300, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BusinessFilterChip(label: svc.filters.sortBy),
                BusinessFilterChip(label: svc.filters.location),
                BusinessFilterChip(label: svc.filters.ageRange),
              ],
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState == ConnectionState.waiting && users.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: WtvaColors.neutral50)),
              )
            else
              ...users.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UserTile(user: u),
                ),
              ),
          ],
        );
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final BusinessTalentProfile user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusinessUserDetailScreen(user: user)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  backgroundColor: WtvaColors.night200,
                  child: user.avatarUrl == null ? Text(user.name[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                        '${user.tier} · ${user.points} pts · ${user.city}',
                        style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WtvaGradientButton(
            label: 'Book user',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusinessBookUserScreen(user: user)),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessBrowseFiltersScreen extends StatefulWidget {
  const BusinessBrowseFiltersScreen({super.key});

  @override
  State<BusinessBrowseFiltersScreen> createState() => _BusinessBrowseFiltersScreenState();
}

class _BusinessBrowseFiltersScreenState extends State<BusinessBrowseFiltersScreen> {
  late BusinessBrowseFilters _f;

  @override
  void initState() {
    super.initState();
    _f = BusinessService.instance.filters.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              BusinessService.instance.updateFilters(_f);
              Navigator.pop(context);
            },
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _filterSection('Sort by', ['Highest rank', 'Lowest rank', 'Recently active'], _f.sortBy, (v) => _f.sortBy = v),
          _filterSection('Date posted', ['Any time', 'Today', 'This week'], _f.datePosted, (v) => _f.datePosted = v),
          _filterSection('Location', ['Any', 'Houston', 'Austin', 'Dallas'], _f.location, (v) => _f.location = v),
          _filterSection('Age', ['Any', '21–25', '21–35', '26–40'], _f.ageRange, (v) => _f.ageRange = v),
          _filterSection('Gender', ['Any', 'Male', 'Female', 'Non-binary'], _f.gender, (v) => _f.gender = v),
        ],
      ),
    );
  }

  Widget _filterSection(String title, List<String> options, String current, ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              return BusinessFilterChip(
                label: o,
                selected: current == o,
                onTap: () => setState(() => onPick(o)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BusinessUserDetailScreen extends StatelessWidget {
  final BusinessTalentProfile user;

  const BusinessUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusinessTalentChatScreen(user: user)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              backgroundColor: WtvaColors.night200,
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(
            '${user.tier} · ${user.points} points',
            textAlign: TextAlign.center,
            style: const TextStyle(color: WtvaColors.neutral300),
          ),
          const SizedBox(height: 8),
          Text('${user.city} · ${user.age} · ${user.gender}', textAlign: TextAlign.center, style: const TextStyle(color: WtvaColors.neutral300)),
          const SizedBox(height: 20),
          Text(user.bio, style: const TextStyle(color: WtvaColors.neutral200, height: 1.5)),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Book user',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusinessBookUserScreen(user: user)),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessTalentChatScreen extends StatefulWidget {
  final BusinessTalentProfile user;

  const BusinessTalentChatScreen({super.key, required this.user});

  @override
  State<BusinessTalentChatScreen> createState() => _BusinessTalentChatScreenState();
}

class _BusinessTalentChatScreenState extends State<BusinessTalentChatScreen> {
  final _ctrl = TextEditingController();
  final _msgs = <({String text, bool me})>[
    (text: 'Hey! Interested in hosting you Saturday.', me: true),
    (text: 'Sounds great — what time?', me: false),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.me ? WtvaColors.neutral50 : WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.me ? WtvaColors.onPrimary : WtvaColors.neutral100),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final t = _ctrl.text.trim();
                      if (t.isEmpty) return;
                      setState(() {
                        _msgs.add((text: t, me: true));
                        _ctrl.clear();
                      });
                    },
                    icon: const Icon(Icons.send, color: WtvaColors.neutral50),
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
