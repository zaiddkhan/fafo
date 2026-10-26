enum NudgeFeedType { friend, group }
enum NudgeStatus { active, acceptedTimer, resolved, expired }
enum NudgeVote { yes, no }

String nudgeFeedTypeToJson(NudgeFeedType value) => value == NudgeFeedType.friend ? 'friend' : 'group';
NudgeFeedType nudgeFeedTypeFromJson(String? value) =>
    value == 'group' ? NudgeFeedType.group : NudgeFeedType.friend;
String nudgeVoteToJson(NudgeVote value) => value == NudgeVote.yes ? 'yes' : 'no';

NudgeStatus nudgeStatusFromJson(String? value) => switch (value) {
      'accepted_timer' => NudgeStatus.acceptedTimer,
      'resolved' => NudgeStatus.resolved,
      'expired' => NudgeStatus.expired,
      _ => NudgeStatus.active,
    };

class NudgeResponse {
  const NudgeResponse({
    required this.id,
    required this.senderUid,
    required this.title,
    required this.responseWindowMinutes,
    required this.status,
    required this.expiresAt,
    required this.reminderCount,
    required this.reminderLimit,
    required this.votes,
    required this.yesCount,
    required this.voterCount,
    required this.expectedVoterCount,
    required this.createdAt,
    this.location,
    this.acceptedTimerStartedAt,
    this.nextReminderAvailableAt,
    this.resolvedAt,
    this.feedType = NudgeFeedType.friend,
    this.targetId,
    this.answerBy,
    this.goAt,
    this.outcome,
    this.description,
    this.questId,
    this.questDifficulty,
    this.senderName,
    this.targetName,
    this.yesNames = const [],
  });

  final String id;
  final String senderUid;
  final String title;
  final String? location;
  final int responseWindowMinutes;
  final NudgeStatus status;
  final DateTime expiresAt;
  final DateTime? acceptedTimerStartedAt;
  final int reminderCount;
  final int reminderLimit;
  final DateTime? nextReminderAvailableAt;
  final Map<String, String> votes;
  final int yesCount;
  final int voterCount;
  final int expectedVoterCount;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final NudgeFeedType feedType;
  final String? targetId;

  /// V3 timing: answer window end (sent + 10 min) and go time (first yes + N).
  /// Every timer derives from these server timestamps, never a local counter.
  final DateTime? answerBy;
  final DateTime? goAt;

  /// "yes" | "no" | "expired" once resolved.
  final String? outcome;
  final String? description;
  final String? questId;
  final String? questDifficulty;
  final String? senderName;

  /// Friend's name (one-to-one) or the group's name.
  final String? targetName;

  /// Group nudges: names of members who said yes.
  final List<String> yesNames;

  /// The sender's countdown after yes (5, 10 or 15). Same field pre-V3.
  int get countdownMinutes => responseWindowMinutes;
  bool get isGroup => feedType == NudgeFeedType.group;
  bool get isPending => status == NudgeStatus.active;
  bool get isAccepted => status == NudgeStatus.acceptedTimer;
  bool get isLive => isPending || isAccepted;
  bool get isQuest => questId != null;
  DateTime get answerDeadline => answerBy ?? expiresAt;
  DateTime get goTime => goAt ?? expiresAt;
  String? voteOf(String uid) => votes[uid];

  bool get isResolved => status == NudgeStatus.resolved || status == NudgeStatus.expired;

  factory NudgeResponse.fromJson(Map<String, dynamic> json) {
    return NudgeResponse(
      id: json['id'] as String,
      senderUid: json['sender_uid'] as String,
      title: json['title'] as String? ?? '',
      location: json['location'] as String?,
      responseWindowMinutes: json['response_window_minutes'] as int? ?? 5,
      status: nudgeStatusFromJson(json['status'] as String?),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedTimerStartedAt: json['accepted_timer_started_at'] == null ? null : DateTime.parse(json['accepted_timer_started_at'] as String),
      reminderCount: json['reminder_count'] as int? ?? 0,
      reminderLimit: json['reminder_limit'] as int? ?? 0,
      nextReminderAvailableAt: json['next_reminder_available_at'] == null ? null : DateTime.parse(json['next_reminder_available_at'] as String),
      votes: ((json['votes'] as Map?) ?? {}).map((key, value) => MapEntry(key.toString(), value.toString())),
      yesCount: json['yes_count'] as int? ?? 0,
      voterCount: json['voter_count'] as int? ?? 0,
      expectedVoterCount: json['expected_voter_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null ? null : DateTime.parse(json['resolved_at'] as String),
      feedType: nudgeFeedTypeFromJson(json['feed_type'] as String?),
      targetId: json['target_id'] as String?,
      answerBy: json['answer_by'] == null ? null : DateTime.parse(json['answer_by'] as String),
      goAt: json['go_at'] == null ? null : DateTime.parse(json['go_at'] as String),
      outcome: json['outcome'] as String?,
      description: json['description'] as String?,
      questId: json['quest_id'] as String?,
      questDifficulty: json['quest_difficulty'] as String?,
      senderName: json['sender_name'] as String?,
      targetName: json['target_name'] as String?,
      yesNames: ((json['yes_names'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
