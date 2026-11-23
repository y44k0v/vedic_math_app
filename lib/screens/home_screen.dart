import 'package:material_ui/material_ui.dart';

import '../data/vedic_catalog.dart';
import '../database/db_helper.dart';
import '../models/vedic_models.dart';
import 'progress_screen.dart';
import 'theory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  VedicCategory? _filterCategory;
  Map<String, Map<String, dynamic>> _progressMap = {};
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await DatabaseHelper.instance.getAllItemProgress();
    final total = await DatabaseHelper.instance.getTotalScore();
    if (!mounted) return;
    setState(() {
      _progressMap = progress;
      _totalScore = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterCategory == null
        ? vedicCatalog
        : vedicCatalog.where((e) => e.category == _filterCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTab == 0 ? 'Vedic Mathematics' : 'Your Progress'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.stars_rounded, size: 18),
              label: Text('$_totalScore pts'),
            ),
          ),
        ],
      ),
      body: _selectedTab == 0
          ? Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All (29)'),
                        selected: _filterCategory == null,
                        onSelected: (_) =>
                            setState(() => _filterCategory = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('16 Sutras'),
                        selected: _filterCategory == VedicCategory.sutra,
                        onSelected: (_) => setState(
                          () => _filterCategory = VedicCategory.sutra,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('13 Sub-Sutras'),
                        selected: _filterCategory == VedicCategory.subSutra,
                        onSelected: (_) => setState(
                          () => _filterCategory = VedicCategory.subSutra,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final stats = _progressMap[item.id];
                      final bestScore = stats?['best_score'] as int? ?? 0;
                      final isMastered = bestScore >= 200; // >= 20/25 correct

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isMastered
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            child: Text(
                              '${item.category == VedicCategory.sutra ? "S" : "SS"}${item.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            item.sanskritName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '"${item.translation}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(item.summary),
                              if (stats != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Best: $bestScore / 250 pts  •  Attempts: ${stats['attempts']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            isMastered
                                ? Icons.verified_rounded
                                : Icons.chevron_right_rounded,
                            color: isMastered
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TheoryScreen(item: item),
                              ),
                            );
                            _loadProgress();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const ProgressScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) {
          setState(() => _selectedTab = idx);
          if (idx == 0) _loadProgress();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learn & Drill',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
