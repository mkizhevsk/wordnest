import 'dart:math';

class StringRandomGenerator {
  // Private constructor
  StringRandomGenerator._privateConstructor();

  // Singleton instance
  static final StringRandomGenerator _instance =
      StringRandomGenerator._privateConstructor();

  // Getter to access the singleton instance
  static StringRandomGenerator get instance => _instance;

  final Random _rng = Random();
  final String _characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  String _generateString(int length) {
    return String.fromCharCodes(Iterable.generate(length,
        (_) => _characters.codeUnitAt(_rng.nextInt(_characters.length))));
  }

  String getValue() {
    return _generateString(14);
  }
}
