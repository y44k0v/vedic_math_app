import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../database/db_helper.dart';
import '../engine/exercise_generator.dart';
import '../models/vedic_models.dart';

class ExerciseScreen extends StatefulWidget {
  final VedicItem item;
  final Player player;

  const ExerciseScreen({super.key, required this.item, required this.player});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  static const int totalQuestions = 25;

  final ExerciseGenerator _generator = ExerciseGenerator();
  final TextEditingController _primaryCtrl = TextEditingController();
  final TextEditingController _secondaryCtrl = TextEditingController();

  late List<MathProblem> _problems;
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  String? _selectedYesNo;
  bool _hasSubmitted = false;
  bool _isCorrect = false;
  bool _solutionViewedBeforeSubmit = false;

  @override
  void initState() {
    super.initState();
    _problems = _generator.generateSession(
      widget.item.id,
      count: totalQuestions,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _submitAnswer() {
    if (_hasSubmitted) return;
    final problem = _problems[_currentIndex];
    bool correct = false;

    switch (problem.answerType) {
      case AnswerType.integer:
        correct = _primaryCtrl.text.trim() == problem.primaryAnswer;
        break;
      case AnswerType.quotientRemainder:
      case AnswerType.pairXY:
        correct =
            _primaryCtrl.text.trim() == problem.primaryAnswer &&
            _secondaryCtrl.text.trim() == (problem.secondaryAnswer ?? '');
        break;
      case AnswerType.booleanYesNo:
        correct = _selectedYesNo == problem.primaryAnswer;
        break;
    }

    setState(() {
      _hasSubmitted = true;
      _isCorrect = correct;
      if (correct) {
        _correctCount++;
        if (!_solutionViewedBeforeSubmit) {
          _score += 10;
        }
      }
    });
  }

  void _showSolutionSheet() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard before opening sheet
    if (!_hasSubmitted) {
      setState(() => _solutionViewedBeforeSubmit = true);
    }
    final problem = _problems[_currentIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vedic Solution',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_solutionViewedBeforeSubmit && !_hasSubmitted) ...[
                const SizedBox(height: 6),
                Text(
                  'Note: Viewing the solution before answering forfeits the 10 pts for this question.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                problem.solutionSteps,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem.secondaryAnswer != null
                      ? 'Answer: ${problem.primaryAnswer}, ${problem.secondaryAnswer}'
                      : 'Answer: ${problem.primaryAnswer}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _primaryCtrl.clear();
        _secondaryCtrl.clear();
        _selectedYesNo = null;
        _hasSubmitted = false;
        _isCorrect = false;
        _solutionViewedBeforeSubmit = false;
      });
    } else {
      _timer?.cancel();
      final record = SessionRecord(
        playerId: widget.player.id!,
        itemId: widget.item.id,
        itemTitle: widget.item.sanskritName,
        score: _score,
        correctCount: _correctCount,
        totalQuestions: totalQuestions,
        durationSeconds: _elapsedSeconds,
        completedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.saveSessionResult(record);
      if (!mounted) return;
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.emoji_events_rounded, size: 48),
        title: const Text('Drill Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item.sanskritName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Score: $_score / 250 pts'),
            Text('Correct: $_correctCount / $totalQuestions'),
            Text('Time: ${_formatTime(_elapsedSeconds)}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to Theory screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problems[_currentIndex];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Q ${_currentIndex + 1} / $totalQuestions'),
        actions: [
          Chip(
            avatar: const Icon(Icons.timer_outlined, size: 18),
            label: Text(_formatTime(_elapsedSeconds)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.stars_rounded, size: 18),
              label: Text('$_score'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar already handles the top status bar
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / totalQuestions,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: colors.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              problem.prompt,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hint: ${problem.hint}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputArea(problem),
                    const SizedBox(height: 16),
                    if (_hasSubmitted)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? Colors.green.withValues(alpha: 0.15)
                              : colors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isCorrect
                              ? (_solutionViewedBeforeSubmit
                                    ? 'Correct! (0 pts because Solution was viewed)'
                                    : 'Correct! +10 points!')
                              : 'Incorrect. Correct Answer: ${problem.primaryAnswer}${problem.secondaryAnswer != null ? ", ${problem.secondaryAnswer}" : ""}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isCorrect
                                ? Colors.green.shade800
                                : colors.onErrorContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _showSolutionSheet,
                      icon: const Icon(Icons.lightbulb_outline, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Solution', maxLines: 1, softWrap: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _hasSubmitted ? _nextQuestion : _submitAnswer,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _hasSubmitted
                              ? (_currentIndex == totalQuestions - 1
                                    ? 'Finish Drill'
                                    : 'Next Question')
                              : 'Check Answer',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(MathProblem problem) {
    switch (problem.answerType) {
      case AnswerType.integer:
        return TextField(
          controller: _primaryCtrl,
          enabled: !_hasSubmitted,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitAnswer(),
        );
      case AnswerType.quotientRemainder:
      case AnswerType.pairXY:
        final label1 = problem.answerType == AnswerType.quotientRemainder
            ? 'Quotient'
            : 'x';
        final label2 = problem.answerType == AnswerType.quotientRemainder
            ? 'Remainder'
            : 'y';
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _primaryCtrl,
                enabled: !_hasSubmitted,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: label1,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _secondaryCtrl,
                enabled: !_hasSubmitted,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: label2,
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
          onSelectionChanged: _hasSubmitted
              ? null
              : (selection) =>
                    setState(() => _selectedYesNo = selection.firstOrNull),
        );
    }
  }
}
