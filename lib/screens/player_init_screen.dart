import 'package:material_ui/material_ui.dart';

import '../database/db_helper.dart';
import '../models/vedic_models.dart';

class PlayerInitScreen extends StatefulWidget {
  final ValueChanged<Player> onPlayerCreated;

  const PlayerInitScreen({super.key, required this.onPlayerCreated});

  @override
  State<PlayerInitScreen> createState() => _PlayerInitScreenState();
}

class _PlayerInitScreenState extends State<PlayerInitScreen> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createFirstPlayer() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final player = await DatabaseHelper.instance.createPlayer(
      _nameCtrl.text.trim(),
      setActive: true,
    );

    if (!mounted) return;
    widget.onPlayerCreated(player);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(
                        Icons.calculate_rounded,
                        size: 42,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Vedic Math',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your player profile to track scores, timers, and progress charts. You can add more players anytime.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Player Name',
                        hintText: 'e.g., Aarav',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a player name';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _createFirstPlayer(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _createFirstPlayer,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(_saving ? 'Creating...' : 'Start Learning'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
