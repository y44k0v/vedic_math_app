import 'package:material_ui/material_ui.dart';

import '../data/vedic_catalog.dart';
import '../database/db_helper.dart';
import '../models/multiplayer_models.dart';
import '../models/vedic_models.dart';
import '../multiplayer/match_client.dart';
import '../multiplayer/match_server.dart';
import 'multiplayer_arena_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final Player player;
  final VoidCallback onMatchFinished;

  const MultiplayerLobbyScreen({
    super.key,
    required this.player,
    required this.onMatchFinished,
  });

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  VedicItem _selectedItem = vedicCatalog.first;
  final _ipCtrl = TextEditingController(text: '192.168.1.');
  final _matchIdCtrl = TextEditingController(text: 'VM-');
  MatchSnapshot? _resumableMatch;
  List<MatchSnapshot> _pastMatches = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCachedMatches();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _matchIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCachedMatches() async {
    final resumable = await DatabaseHelper.instance.getLatestResumableMatch();
    final recent = await DatabaseHelper.instance.getRecentMultiplayerMatches();
    if (!mounted) return;
    setState(() {
      _resumableMatch = resumable;
      _pastMatches = recent;
    });
  }

  Future<void> _hostMatch() async {
    setState(() => _busy = true);
    final server = MatchServer();
    final snap = await server.startNewMatch(
      item: _selectedItem,
      hostPlayer: widget.player,
    );

    final client = MatchClient(
      localPlayer: widget.player,
      hostIp: '127.0.0.1',
      port: snap.port,
      matchId: snap.matchId,
      isHost: true,
      initialSnapshot: snap,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerArenaScreen(client: client, server: server),
      ),
    );
    await _loadCachedMatches();
    widget.onMatchFinished();
  }

  Future<void> _joinOrResumeMatch({
    required String hostIp,
    required int port,
    required String matchId,
    required bool asHost,
    MatchSnapshot? cachedSnapshot,
  }) async {
    setState(() => _busy = true);
    MatchServer? server;
    String connectIp = hostIp;

    if (asHost && cachedSnapshot != null) {
      server = MatchServer();
      final resumed = await server.resumeHostMatch(cachedSnapshot);
      if (resumed == null) {
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not restore host match data.')),
          );
        }
        return;
      }
      connectIp = '127.0.0.1';
    }

    final client = MatchClient(
      localPlayer: widget.player,
      hostIp: connectIp,
      port: port,
      matchId: matchId.trim().toUpperCase(),
      isHost: asHost,
      initialSnapshot: cachedSnapshot,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerArenaScreen(client: client, server: server),
      ),
    );
    await _loadCachedMatches();
    widget.onMatchFinished();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (_resumableMatch != null) ...[
          Card(
            color: colors.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restore_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'Resume Match (${_resumableMatch!.matchId})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_resumableMatch!.itemTitle} • Q${_resumableMatch!.currentQuestionIndex + 1}/${_resumableMatch!.totalQuestions} • ${_resumableMatch!.isHost ? "Host" : "Client"}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _joinOrResumeMatch(
                            hostIp: _resumableMatch!.hostIp,
                            port: _resumableMatch!.port,
                            matchId: _resumableMatch!.matchId,
                            asHost: _resumableMatch!.isHost,
                            cachedSnapshot: _resumableMatch,
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume Instantly'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // HOST CARD
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Host a WiFi Match',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your phone acts as the authoritative server over local WiFi.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VedicItem>(
                  initialValue: _selectedItem,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Sutra / Sub-Sutra',
                    border: OutlineInputBorder(),
                  ),
                  items: vedicCatalog
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.category == VedicCategory.sutra ? "S" : "SS"}${item.number}: ${item.sanskritName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedItem = val);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _hostMatch,
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Create Match Lobby'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // JOIN / REJOIN CARD
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join or Rejoin via WiFi',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ipCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Host WiFi IP Address',
                    hintText: 'e.g., 192.168.1.42',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _matchIdCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Match ID',
                    hintText: 'e.g., VM-4821',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _joinOrResumeMatch(
                          hostIp: _ipCtrl.text.trim(),
                          port: MatchServer.defaultPort,
                          matchId: _matchIdCtrl.text.trim(),
                          asHost: false,
                        ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Join / Rejoin Match'),
                ),
              ],
            ),
          ),
        ),

        if (_pastMatches.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Recent Competitors & Matches',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._pastMatches.map((m) {
            final summary = m.competitors
                .map((c) => '${c.playerName}: ${c.score} pts')
                .join('  •  ');
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${m.matchId} — ${m.itemTitle}'),
                subtitle: Text(summary),
                trailing: Text(m.status.name),
              ),
            );
          }),
        ],
      ],
    );
  }
}
