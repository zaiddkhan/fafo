class ProfileStatsResponse {
  const ProfileStatsResponse({
    required this.upcomingEvents,
    required this.eventsJoined,
    required this.sideQuestsActivated,
    required this.friendsCount,
    required this.currentStreak,
  });

  final int upcomingEvents;
  final int eventsJoined;
  final int sideQuestsActivated;
  final int friendsCount;
  final int currentStreak;

  factory ProfileStatsResponse.fromJson(Map<String, dynamic> json) {
    return ProfileStatsResponse(
      upcomingEvents: json['upcoming_events'] as int? ?? 0,
      eventsJoined: json['events_joined'] as int? ?? 0,
      sideQuestsActivated: json['side_quests_activated'] as int? ?? 0,
      friendsCount: json['friends_count'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
    );
  }
}
