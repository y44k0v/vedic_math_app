import 'package:material_ui/material_ui.dart';

import '../models/multiplayer_models.dart';
import '../models/vedic_models.dart';
import '../multiplayer/match_client.dart';
import '../multiplayer/match_server.dart';

class MultiplayerArenaScreen extends StatefulWidget {
  final MatchClient client;
  final MatchServer? server;

  const MultiplayerArenaScreen({super.key, required this.client, this.server});

  @override
  State<MultiplayerArenaScreen> createState() => _MultiplayerArenaScreenState();
}

class _MultiplayerArenaScreenState extends State<MultiplayerArenaScreen> {
  final _primaryCtrl = TextEditingController();
  final _secondaryCtrl = TextEditingController();
  String? _selectedYesNo;
  int? _lastClearedQuestionIndex;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onStateChanged);
    widget.client.connect();
  }

  void _onStateChanged() {
    final idx = widget.client.snapshot?.currentQuestionIndex;
    if (idx != null && idx != _lastClearedQuestionIndex) {
      _lastClearedQuestionIndex = idx;
      _primaryCtrl.clear();
      _secondaryCtrl.clear();
      _selectedYesNo = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.client.removeListener(_onStateChanged);
    widget.client.dispose();
    widget.server?.stop();
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final q = widget.client.snapshot?.currentQuestion;
    if (q == null) return;

    if (q.answerType == AnswerType.booleanYesNo) {
      if (_selectedYesNo == null) return;
      widget.client.submitAnswer(primary: _selectedYesNo!);
    } else if (q.answerType == AnswerType.integer) {
      widget.client.submitAnswer(primary: _primaryCtrl.text.trim());
    } else {
      widget.client.submitAnswer(
        primary: _primaryCtrl.text.trim(),
        secondary: _secondaryCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.client.snapshot;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(snap?.matchId ?? widget.client.matchId),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                widget.client.isConnected
                    ? Icons.wifi_rounded
                    : Icons.sync_problem_rounded,
                size: 16,
                color: widget.client.isConnected ? Colors.green : colors.error,
              ),
              label: Text(
                widget.client.isConnected ? 'Live' : 'Reconnecting...',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: snap == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        widget.client.errorMessage ??
                            'Connecting to ${widget.client.hostIp}:${widget.client.port}...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // LIVE COMPETITORS LEADERBOARD
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: snap.competitors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = snap.competitors[i];
                        final isMe =
                            c.playerUuid == widget.client.localPlayer.uuid;
                        return Chip(
                          backgroundColor: isMe
                              ? colors.primaryContainer
                              : null,
                          avatar: Icon(
                            Icons.circle,
                            size: 10,
                            color: c.isConnected ? Colors.green : Colors.grey,
                          ),
                          label: Text(
                            '${c.playerName}: ${c.score} pts (${c.latencyMs}ms)',
                            style: TextStyle(
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: switch (snap.status) {
                      MatchStatus.lobby => _buildLobby(context, snap),
                      MatchStatus.inProgress => _buildInProgress(context, snap),
                      MatchStatus.finished => _buildFinished(context, snap),
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLobby(BuildContext context, MatchSnapshot snap) {
    final hostAddress = widget.server?.hostIp ?? snap.hostIp;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  snap.itemTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Host WiFi IP: $hostAddress'),
                Text('Port: ${snap.port}'),
                Text(
                  'Match ID: ${snap.matchId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Joined Players (${snap.competitors.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...snap.competitors.map(
          (c) => Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(c.playerName),
              trailing: Text('${c.latencyMs} ms'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (snap.isHost)
          FilledButton.icon(
            onPressed: widget.client.startMatch,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start 25-Question Race'),
          )
        else
          const Text(
            'Waiting for Host to start the match...',
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildInProgress(BuildContext context, MatchSnapshot snap) {
    final q = snap.currentQuestion;
    final colors = Theme.of(context).colorScheme;
    final roundClosed = snap.lastRoundWinnerName != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (snap.currentQuestionIndex + 1) / snap.totalQuestions,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  'Question ${snap.currentQuestionIndex + 1} / ${snap.totalQuestions}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (q != null)
                  Card(
                    color: colors.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            q.prompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Hint: ${q.hint}', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (roundClosed)
                  Card(
                    color: Colors.green.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round Winner: ${snap.lastRoundWinnerName} (+10 pts)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Answer: ${snap.lastRoundAnswer}'),
                          if (snap.lastRoundSolution != null) ...[
                            const SizedBox(height: 8),
                            Text(snap.lastRoundSolution!),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (q != null) ...[
                  _buildInputs(q),
                  if (widget.client.feedbackMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.client.feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.client.lastAnswerWasCorrect == true
                            ? Colors.green
                            : colors.error,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (!roundClosed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.client.isConnected ? _submit : null,
                child: const Text('Submit Fast Answer'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputs(PublicQuestion q) {
    switch (q.answerType) {
      case AnswerType.integer:
        return TextField(
          controller: _primaryCtrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        );
      case AnswerType.quotientRemainder:
      case AnswerType.pairXY:
        final l1 = q.answerType == AnswerType.quotientRemainder
            ? 'Quotient'
            : 'x';
        final l2 = q.answerType == AnswerType.quotientRemainder
            ? 'Remainder'
            : 'y';
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _primaryCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l1,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _secondaryCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l2,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        );
      case AnswerType.booleanYesNo:
        return SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Yes', label: Text('Yes')),
            ButtonSegment(value: 'No', label: Text('No')),
          ],
          selected: _selectedYesNo == null ? {} : {_selectedYesNo!},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) =>
              setState(() => _selectedYesNo = s.firstOrNull),
        );
    }
  }

  Widget _buildFinished(BuildContext context, MatchSnapshot snap) {
    final winner = snap.competitors.first;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.emoji_events_rounded, size: 64),
        const SizedBox(height: 12),
        Text(
          'Winner: ${winner.playerName}!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...snap.competitors.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final c = entry.value;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('#$rank')),
              title: Text(c.playerName),
              subtitle: Text('${c.correctWins} fastest round wins'),
              trailing: Text(
                '${c.score} pts',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Lobby'),
        ),
      ],
    );
  }
}
