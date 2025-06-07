// Remove unused import

class User {
  final int? id;
  final String username;
  final String hashedPassword;
  final String salt;
  final String? email;
  final String? profileImagePath;
  final DateTime createdAt;
  final int totalQuizzes;
  final int highScore;
  final DateTime? lastQuizDate;

  User({
    this.id,
    required this.username,
    required this.hashedPassword,
    required this.salt,
    this.email,
    this.profileImagePath,
    DateTime? createdAt,
    this.totalQuizzes = 0,
    this.highScore = 0,
    this.lastQuizDate,
  }) : createdAt = createdAt ?? DateTime.now();

  // Format high score with commas for better readability
  String get formattedHighScore => highScore.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},'
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'hashed_password': hashedPassword,
      'salt': salt,
      'email': email,
      'profile_image_path': profileImagePath,
      'created_at': createdAt.toIso8601String(),
      'total_quizzes': totalQuizzes,
      'high_score': highScore,
      'last_quiz_date': lastQuizDate?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      hashedPassword: map['hashed_password'] as String,
      salt: map['salt'] as String,
      email: map['email'] as String?,
      profileImagePath: map['profile_image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      totalQuizzes: map['total_quizzes'] as int? ?? 0,
      highScore: map['high_score'] as int? ?? 0,
      lastQuizDate: map['last_quiz_date'] != null 
          ? DateTime.parse(map['last_quiz_date'] as String)
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? hashedPassword,
    String? salt,
    String? email,
    String? profileImagePath,
    DateTime? createdAt,
    int? totalQuizzes,
    int? highScore,
    DateTime? lastQuizDate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      salt: salt ?? this.salt,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      highScore: highScore ?? this.highScore,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
    );
  }
}
