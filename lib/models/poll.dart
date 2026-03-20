class PollUser {
  PollUser({
    required this.id,
    required this.username,
    this.role,
  });

  final int id;
  final String username;
  final String? role;

  factory PollUser.fromJson(Map<String, dynamic> json) {
    return PollUser(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String?,
    );
  }
}

class PollVote {
  PollVote({
    required this.pollId,
    required this.status,
    required this.created,
    required this.user,
  });

  final int pollId;
  final bool status;
  final DateTime created;
  final PollUser user;

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      pollId: json['pollId'] as int,
      status: json['status'] as bool,
      created: DateTime.parse(json['created'] as String),
      user: PollUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class Poll {
  Poll({
    required this.id,
    required this.name,
    required this.description,
    required this.eventDate,
    this.imageName,
    this.user,
    this.votes = const [],
  });

  final int id;
  final String name;
  final String description;
  final DateTime eventDate;
  final String? imageName;
  final PollUser? user;
  final List<PollVote> votes;

  int get yesCount => votes.where((v) => v.status).length;
  int get noCount => votes.where((v) => !v.status).length;

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
      imageName: json['imageName'] as String?,
      user: json['user'] != null
          ? PollUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      votes: (json['votes'] as List<dynamic>?)
              ?.map((v) => PollVote.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}