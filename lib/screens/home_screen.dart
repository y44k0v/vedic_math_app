import 'package:material_ui/material_ui.dart';

import '../data/vedic_catalog.dart';
import '../database/db_helper.dart';
import '../models/vedic_models.dart';
import 'players_screen.dart';
import 'progress_screen.dart';
import 'theory_screen.dart';

class HomeScreen extends StatefulWidget {
  final Player initialPlayer;
  final VoidCallback onAllPlayersDeleted;

  const HomeScreen({
    super.key,
    required this.initialPlayer,
    required this.onAllPlayersDeleted,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Player _activePlayer;
  List<Player> _allPlayers = [];
  int _selectedTab = 0;
  VedicCategory? _filterCategory;
  Map<String, Map<String, dynamic>> _progressMap = {};
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _activePlayer = widget.initialPlayer;
    _loadPlayerAndProgress();
  }

  Future<void> _loadPlayerAndProgress() async {
    final active = await DatabaseHelper.instance.getActivePlayer();
    if (active == null) {
      widget.onAllPlayersDeleted();
      return;
    }

    final players = await DatabaseHelper.instance.getAllPlayers();
    final progress = await DatabaseHelper.instance.getAllItemProgress(
      active.id!,
    );
    final total = await DatabaseHelper.instance.getTotalScore(active.id!);

    if (!mounted) return;
    setState(() {
      _activePlayer = active;
      _allPlayers = players;
      _progressMap = progress;
      _totalScore = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Vedic Mathematics', 'Progress', 'Players'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedTab]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Player Menu',
            child: Chip(
              avatar: const Icon(Icons.person_rounded, size: 18),
              label: Text('${_activePlayer.name} • $_totalScore pts'),
            ),
            onSelected: (value) async {
              if (value == 'manage') {
                setState(() => _selectedTab = 2);
              } else {
                final id = int.parse(value);
                await DatabaseHelper.instance.setActivePlayer(id);
                await _loadPlayerAndProgress();
              }
            },
            itemBuilder: (context) => [
              ..._allPlayers.map(
                (p) => PopupMenuItem<String>(
                  value: '${p.id}',
                  child: Row(
                    children: [
                      Icon(
                        p.id == _activePlayer.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(p.name),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Manage Players (CRUD)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildLearnTab(context),
          ProgressScreen(player: _activePlayer),
          PlayersScreen(onPlayersChanged: _loadPlayerAndProgress),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) {
          setState(() => _selectedTab = idx);
          if (idx == 0) _loadPlayerAndProgress();
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
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Players',
          ),
        ],
      ),
    );
  }

  Widget _buildLearnTab(BuildContext context) {
    final filteredItems = _filterCategory == null
        ? vedicCatalog
        : vedicCatalog.where((e) => e.category == _filterCategory).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All (29)'),
                selected: _filterCategory == null,
                onSelected: (_) => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('16 Sutras'),
                selected: _filterCategory == VedicCategory.sutra,
                onSelected: (_) =>
                    setState(() => _filterCategory = VedicCategory.sutra),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('13 Sub-Sutras'),
                selected: _filterCategory == VedicCategory.subSutra,
                onSelected: (_) =>
                    setState(() => _filterCategory = VedicCategory.subSutra),
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
              final isMastered = bestScore >= 200;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isMastered
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          style: Theme.of(context).textTheme.labelMedium,
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
                        builder: (_) =>
                            TheoryScreen(item: item, player: _activePlayer),
                      ),
                    );
                    _loadPlayerAndProgress();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
