import 'vedic_models.dart';

enum MatchStatus { lobby, inProgress, finished }

class CompetitorScore {
  final String playerUuid;
  final String playerName;
  final int score;
  final int correctWins;
  final int latencyMs;
  final bool isConnected;

  const CompetitorScore({
    required this.playerUuid,
    required this.playerName,
    required this.score,
    required this.correctWins,
    required this.latencyMs,
    required this.isConnected,
  });

  CompetitorScore copyWith({
    String? playerName,
    int? score,
    int? correctWins,
    int? latencyMs,
    bool? isConnected,
  }) => CompetitorScore(
    playerUuid: playerUuid,
    playerName: playerName ?? this.playerName,
    score: score ?? this.score,
    correctWins: correctWins ?? this.correctWins,
    latencyMs: latencyMs ?? this.latencyMs,
    isConnected: isConnected ?? this.isConnected,
  );

  Map<String, dynamic> toJson() => {
    'playerUuid': playerUuid,
    'playerName': playerName,
    'score': score,
    'correctWins': correctWins,
    'latencyMs': latencyMs,
    'isConnected': isConnected,
  };

  factory CompetitorScore.fromJson(Map<String, dynamic> json) =>
      CompetitorScore(
        playerUuid: json['playerUuid'] as String,
        playerName: json['playerName'] as String,
        score: json['score'] as int,
        correctWins: json['correctWins'] as int,
        latencyMs: (json['latencyMs'] as int?) ?? 0,
        isConnected: (json['isConnected'] as bool?) ?? true,
      );
}

class PublicQuestion {
  final int index;
  final String prompt;
  final AnswerType answerType;
  final String hint;

  const PublicQuestion({
    required this.index,
    required this.prompt,
    required this.answerType,
    required this.hint,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'prompt': prompt,
    'answerType': answerType.name,
    'hint': hint,
  };

  factory PublicQuestion.fromJson(Map<String, dynamic> json) => PublicQuestion(
    index: json['index'] as int,
    prompt: json['prompt'] as String,
    answerType: AnswerType.values.byName(json['answerType'] as String),
    hint: json['hint'] as String,
  );
}

class MatchSnapshot {
  final String matchId;
  final String hostIp;
  final int port;
  final String itemId;
  final String itemTitle;
  final bool isHost;
  final MatchStatus status;
  final int currentQuestionIndex;
  final int totalQuestions;
  final PublicQuestion? currentQuestion;
  final List<CompetitorScore> competitors;
  final String? lastRoundWinnerName;
  final String? lastRoundAnswer;
  final String? lastRoundSolution;
  final bool recordedInHistory;

  const MatchSnapshot({
    required this.matchId,
    required this.hostIp,
    required this.port,
    required this.itemId,
    required this.itemTitle,
    required this.isHost,
    required this.status,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.currentQuestion,
    required this.competitors,
    this.lastRoundWinnerName,
    this.lastRoundAnswer,
    this.lastRoundSolution,
    this.recordedInHistory = false,
  });

  MatchSnapshot copyWith({
    String? hostIp,
    int? port,
    MatchStatus? status,
    int? currentQuestionIndex,
    PublicQuestion? currentQuestion,
    bool clearQuestion = false,
    List<CompetitorScore>? competitors,
    String? lastRoundWinnerName,
    String? lastRoundAnswer,
    String? lastRoundSolution,
    bool clearRoundResult = false,
    bool? recordedInHistory,
  }) => MatchSnapshot(
    matchId: matchId,
    hostIp: hostIp ?? this.hostIp,
    port: port ?? this.port,
    itemId: itemId,
    itemTitle: itemTitle,
    isHost: isHost,
    status: status ?? this.status,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    totalQuestions: totalQuestions,
    currentQuestion: clearQuestion
        ? null
        : (currentQuestion ?? this.currentQuestion),
    competitors: competitors ?? this.competitors,
    lastRoundWinnerName: clearRoundResult
        ? null
        : (lastRoundWinnerName ?? this.lastRoundWinnerName),
    lastRoundAnswer: clearRoundResult
        ? null
        : (lastRoundAnswer ?? this.lastRoundAnswer),
    lastRoundSolution: clearRoundResult
        ? null
        : (lastRoundSolution ?? this.lastRoundSolution),
    recordedInHistory: recordedInHistory ?? this.recordedInHistory,
  );
}
