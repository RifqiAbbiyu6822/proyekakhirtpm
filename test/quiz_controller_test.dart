import 'package:flutter_test/flutter_test.dart';
import 'package:historyquizapp/controllers/quiz_controller.dart';
import 'package:logging/logging.dart';

void main() {
  // Sembunyikan log selama tes agar output bersih
  Logger.root.level = Level.OFF;
  
  group('QuizController (Hard Difficulty Test)', () {
    late QuizController quizController;

    // Menyiapkan QuizController sebelum setiap tes berjalan
    setUp(() async {
      quizController = QuizController();
      // Mengatur kesulitan ke 'hard' untuk menggunakan daftar pertanyaan internal
      // dan menghindari panggilan API, sehingga memungkinkan tes yang andal.
      quizController.gameState.difficulty = 'hard';
      // Memulai permainan untuk menginisialisasi state yang diperlukan
      await quizController.startGame();
      // Mengambil pertanyaan pertama secara alami menggunakan metode yang ada
      await quizController.fetchQuestion();
    });

    test('fetchQuestion harus berhasil memuat pertanyaan untuk tingkat kesulitan hard', () {
      // Setelah `setUp`, `currentQuestion` seharusnya sudah terisi
      expect(quizController.currentQuestion, isNotNull);
      // Memastikan pertanyaan yang dimuat memang dari kategori 'hard'
      expect(quizController.currentQuestion?.difficulty, 'hard');
    });

    test('Jawaban yang benar harus meningkatkan skor', () {
      // Memastikan ada pertanyaan saat ini sebelum menjawab
      final question = quizController.currentQuestion;
      expect(question, isNotNull, reason: "Pertanyaan tidak berhasil dimuat dalam setup");

      final initialScore = quizController.gameState.score;
      final correctAnswer = question!.correctAnswer;

      // Memberikan jawaban yang benar
      quizController.answerQuestion(correctAnswer);

      // Verifikasi bahwa skor bertambah sesuai poin kesulitan 'hard' (30)
      expect(quizController.gameState.score, greaterThan(initialScore));
      expect(quizController.gameState.score, initialScore + 30);
    });

    test('Jawaban yang salah harus mengurangi nyawa', () {
      // Memastikan ada pertanyaan saat ini
      final question = quizController.currentQuestion;
      expect(question, isNotNull, reason: "Pertanyaan tidak berhasil dimuat dalam setup");

      final initialLives = quizController.gameState.lives;
      // Membuat jawaban yang salah dengan membalik jawaban yang benar
      final wrongAnswer = question!.correctAnswer == 'True' ? 'False' : 'True';
      
      // Memberikan jawaban yang salah
      quizController.answerQuestion(wrongAnswer);
      
      // Verifikasi bahwa nyawa berkurang satu
      expect(quizController.gameState.lives, lessThan(initialLives));
      expect(quizController.gameState.lives, initialLives - 1);
    });

    test('resetGame harus mengembalikan state game ke kondisi awal', () async {
      // Mengubah state dengan menjawab satu pertanyaan
      quizController.answerQuestion(quizController.currentQuestion!.correctAnswer);
      await quizController.fetchQuestion();

      // Melakukan reset
      quizController.resetGame();

      // Verifikasi bahwa semua state kembali ke nilai default
      expect(quizController.gameState.score, 0);
      expect(quizController.gameState.lives, 5);
      expect(quizController.gameState.level, 1);
      expect(quizController.gameState.difficulty, 'easy'); // Kesulitan harus kembali ke 'easy'
      expect(quizController.currentQuestion, isNull); // Pertanyaan saat ini harus kosong setelah reset
    });
  });
}