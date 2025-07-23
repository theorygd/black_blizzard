// blizzard.dart
// Entry point for black_blizzard project
// Author: theoryg + cursor x chatgpt
// This file organizes all parts and starts the game.

library blackblizzard;

part 'log.dart';
part 'core/game.dart';
part 'core/player.dart';
part 'core/role.dart';
part 'core/location.dart';
part 'core/action.dart';
part 'core/character.dart';
part 'core/skill.dart';
part 'util/typedefs.dart';

void main() {
  // Initialize the game
  final game = BlackBlizzardGame();
  game.start();
}
