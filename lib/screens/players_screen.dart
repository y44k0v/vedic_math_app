import 'package:material_ui/material_ui.dart';

import '../database/db_helper.dart';
import '../models/vedic_models.dart';

class PlayersScreen extends StatefulWidget {
  final VoidCallback onPlayersChanged;

  const PlayersScreen({super.key, required this.onPlayersChanged});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<Player> _players = [];
  Map<int, int> _scoresByPlayer = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final list = await DatabaseHelper.instance.getAllPlayers();
    final scores = await DatabaseHelper.instance.getAllPlayersTotalScores();
    if (!mounted) return;
    setState(() {
      _players = list;
      _scoresByPlayer = scores;
      _loading = false;
    });
  }

  Future<void> _showCreateOrEditDialog({Player? existing}) async {
    final resultName = await showDialog<String>(
      context: context,
      builder: (_) => _PlayerNameDialog(initialName: existing?.name),
    );

    if (resultName == null) return;

    if (existing == null) {
      await DatabaseHelper.instance.createPlayer(resultName, setActive: true);
    } else {
      await DatabaseHelper.instance.updatePlayerName(existing.id!, resultName);
    }

    await _loadPlayers();
    widget.onPlayersChanged();
  }

  Future<void> _confirmDelete(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Delete Player?'),
        content: Text(
          'Delete "${player.name}"? All scores and progress history for this player will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deletePlayer(player.id!);
      await _loadPlayers();
      widget.onPlayersChanged();
    }
  }

  Future<void> _switchPlayer(Player player) async {
    if (player.isActive) return;
    await DatabaseHelper.instance.setActivePlayer(player.id!);
    await _loadPlayers();
    widget.onPlayersChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final totalPts = _scoresByPlayer[player.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: player.isActive ? colors.primaryContainer : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () => _switchPlayer(player),
                    leading: CircleAvatar(
                      backgroundColor: player.isActive
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      foregroundColor: player.isActive
                          ? colors.onPrimary
                          : null,
                      child: Text(
                        player.name.isNotEmpty
                            ? player.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isActive) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text('Active'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Total Score: $totalPts pts'),
                        Text(
                          'UUID: ${player.uuid}',
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit name',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _showCreateOrEditDialog(existing: player),
                        ),
                        IconButton(
                          tooltip: 'Delete player',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(player),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrEditDialog(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Player'),
      ),
    );
  }
}

class _PlayerNameDialog extends StatefulWidget {
  final String? initialName;

  const _PlayerNameDialog({this.initialName});

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Player Name' : 'Add New Player'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
