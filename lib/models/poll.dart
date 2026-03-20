class Poll {
  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imageName,
    this.nbYes,
    this.nbNo,
    this.nbMaybe,
    this.userVote,
  });

  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String? imageName;
  final int? nbYes;
  final int? nbNo;
  final int? nbMaybe;
  final String? userVote;

  factory Poll.fromJson(Map<String, dynamic> json) {
    final rawDate =
        json['date'] ?? json['eventDate'] ?? json['createdAt'] ?? '';

    return Poll(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: (json['description'] ?? json['content'] ?? '') as String,
      date: rawDate is String && rawDate.isNotEmpty
          ? DateTime.parse(rawDate)
          : DateTime.now(),
      imageName: json['imageName'] as String?,
      nbYes: json['nbYes'] as int?,
      nbNo: json['nbNo'] as int?,
      nbMaybe: json['nbMaybe'] as int?,
      userVote: json['userVote'] as String?,
    );
  }
}