part of blackblizzard;

// Clue abstract class (base for all clues)

part 'trace.dart';
part 'leftout.dart';

abstract class Clue {
  final String name;
  final String description;
  final String chineseName;
  final bool isExtra; // Whether this is an extra clue (requires special ability to discover)

  Clue(this.name, this.description, this.chineseName, {this.isExtra = false});

  /// Whether this clue is visible to the user
  bool isVisible(Player user, [Map<String, dynamic>? context]);

  /// Called when a player picks up this clue
  void onPickup(Player user, [Map<String, dynamic>? context]);
}
