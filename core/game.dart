// core/game.dart
// Game abstract class and BlackBlizzardGame main process

part of blackblizzard;

import 'player.dart';
import '../channel/channel.dart';

abstract class Game {
  void start();
}

class BlackBlizzardGame extends Game {
  final List<Player> players = [];
  final List<Channel> channels = [];

  BlackBlizzardGame();

  @override
  void start() {
    Log().write('Game started.');
    print('暴风雪山庄游戏开始！');
    // TODO: Initialize players, locations, roles, etc.
    // TODO: Main game loop
    // TODO: Output to channels
    // TODO: Call Log().write for all major events
  }
} 