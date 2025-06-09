class Question {
  final String question;
  final String correctAnswer; // Expected to be "True" or "False"
  final String difficulty;
  final String category;
  final int questionId;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    required this.questionId,
  });
  
  /// Create Question from JSON with null safety
  factory Question.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Return a default question if json is null
      return Question(
        question: 'Is Flutter a UI framework?',
        correctAnswer: 'True',
        difficulty: 'easy',
        category: 'Programming',
        questionId: 'default_question'.hashCode,
      );
    }
    
    final rawQuestion = json['question']?.toString() ?? 'Default question?';
    final rawCorrectAnswer = json['correct_answer']?.toString() ?? 'True';
    final rawDifficulty = json['difficulty']?.toString() ?? 'easy';
    final rawCategory = json['category']?.toString() ?? 'General';

    return Question(
      question: _decodeHtml(rawQuestion),
      correctAnswer: _decodeHtml(rawCorrectAnswer),
      difficulty: rawDifficulty,
      category: _decodeHtml(rawCategory),
      questionId: rawQuestion.hashCode,
    );
  }

  /// Since answers always True or False for boolean quiz,
  /// we return fixed list here:
  List<String> get allAnswers => ['True', 'False'];

  /// Decode HTML entities with null safety
  static String _decodeHtml(String? text) {
    if (text == null) return '';
    
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&hellip;', '...')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');
  }

  /// Convert to JSON with null safety
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_answer': correctAnswer,
      'difficulty': difficulty,
      'category': category,
      'questionId': questionId,
    };
  }

  /// Create a copy of the question
  Question copyWith({
    String? question,
    String? correctAnswer,
    String? difficulty,
    String? category,
    int? questionId,
  }) {
    return Question(
      question: question ?? this.question,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      questionId: questionId ?? this.questionId,
    );
  }

  /// Check if the question is valid
  bool get isValid {
    return question.isNotEmpty && 
           correctAnswer.isNotEmpty && 
           (correctAnswer == 'True' || correctAnswer == 'False') &&
           difficulty.isNotEmpty &&
           category.isNotEmpty;
  }

  /// Get formatted question text
  String get formattedQuestion {
    String formatted = question.trim();
    if (!formatted.endsWith('?') && !formatted.endsWith('.')) {
      formatted += '?';
    }
    return formatted;
  }

  /// Get difficulty level as number (for sorting/comparison)
  int get difficultyLevel {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 1;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question &&
        other.question == question &&
        other.correctAnswer == correctAnswer &&
        other.difficulty == difficulty &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(
    question,
    correctAnswer,
    difficulty,
    category,
  );

  @override
  String toString() {
    return 'Question(question: "$question", correctAnswer: "$correctAnswer", difficulty: "$difficulty", category: "$category", id: $questionId)';
  }
}