import 'package:flutter/material.dart';
import '../../services/drivers_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/driver_company_card.dart';
import 'driver_detail_screen.dart';

class DriversBrowseScreen extends StatefulWidget {
  const DriversBrowseScreen({super.key});

  @override
  State<DriversBrowseScreen> createState() => _DriversBrowseScreenState();
}

class _DriversBrowseScreenState extends State<DriversBrowseScreen> {
  final _searchController = TextEditingController();
  late Future<List<DriverCompanyRecord>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _driversFuture = DriversRepository.instance.listPublished(
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Find a driver', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: WtvaColors.neutral100),
              decoration: InputDecoration(
                hintText: 'Search drivers, cities...',
                hintStyle: const TextStyle(color: WtvaColors.neutral300),
                prefixIcon: const Icon(Icons.search, color: WtvaColors.neutral300),
                filled: true,
                fillColor: WtvaColors.dark400,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.85)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.85)),
                ),
              ),
              onSubmitted: (_) => setState(_reload),
              onChanged: (_) => setState(_reload),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DriverCompanyRecord>>(
              future: _driversFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final drivers = snapshot.data ?? const [];
                if (drivers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _searchController.text.trim().isNotEmpty
                            ? 'No drivers match your search.'
                            : 'No drivers listed yet. Check back soon.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: WtvaColors.neutral300),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final company = drivers[i];
                    return DriverCompanyCard(
                      company: company,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverDetailScreen(companyId: company.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
