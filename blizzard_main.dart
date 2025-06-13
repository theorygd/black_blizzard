import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'src/core/game_engine.dart';
import 'src/core/log_manager.dart';
import 'src/models/game_state.dart';
import 'src/models/player.dart';
import 'src/models/character.dart';
import 'src/models/location.dart';
import 'src/lang/language_manager.dart';

/// 暴风雪山庄 - 导演辅助程序
/// Blizzard Villa - Director Assistant Program
/// 
/// 基于名字竞技场的面向对象架构开发
/// Built with object-oriented architecture inspired by Namerena
void main() async {
  print('=== 暴风雪山庄导演辅助系统 ===');
  print('Blizzard Villa Director Assistant System');
  print('');

  // Initialize core systems
  final logManager = LogManager();
  final languageManager = LanguageManager();
  await languageManager.loadLanguage('zh');
  
  final gameEngine = GameEngine(
    logManager: logManager,
    languageManager: languageManager,
  );

  // Start the game setup
  await setupGame(gameEngine);
  
  // Main game loop
  await runGameLoop(gameEngine);
  
  // Save logs
  await logManager.saveToFile('game_log_${DateTime.now().millisecondsSinceEpoch}.log');
  
  print('\n游戏结束，感谢使用暴风雪山庄导演辅助系统！');
}

/// 游戏设置阶段
Future<void> setupGame(GameEngine engine) async {
  print('=== 游戏准备阶段 ===');
  
  // Get number of players
  int playerCount = await getPlayerCount();
  engine.initializeGame(playerCount);
  
  // Add players
  for (int i = 0; i < playerCount; i++) {
    String playerName = await getPlayerName(i + 1);
    engine.addPlayer(playerName);
  }
  
  // Assign characters
  await assignCharacters(engine);
  
  // Set initial locations
  await setInitialLocations(engine);
  
  print('\n游戏准备完成！');
}

/// 获取玩家数量
Future<int> getPlayerCount() async {
  while (true) {
    stdout.write('请输入玩家数量（6-10人）: ');
    String? input = stdin.readLineSync();
    if (input != null) {
      int? count = int.tryParse(input);
      if (count != null && count >= 6 && count <= 10) {
        return count;
      }
    }
    print('错误：请输入6-10之间的数字');
  }
}

/// 获取玩家姓名
Future<String> getPlayerName(int index) async {
  stdout.write('请输入第${index}位玩家姓名: ');
  String? name = stdin.readLineSync();
  return name ?? '玩家$index';
}

/// 分配角色
Future<void> assignCharacters(GameEngine engine) async {
  print('\n=== 角色分配 ===');
  
  // Show available characters
  engine.showAvailableCharacters();
  
  // Let players choose characters in order
  for (Player player in engine.gameState.players) {
    String characterType = await getCharacterChoice(player.name);
    engine.assignCharacter(player, characterType);
  }
  
  // Randomly assign murderer and fool
  engine.assignSpecialRoles();
  
  print('角色分配完成！');
}

/// 获取角色选择
Future<String> getCharacterChoice(String playerName) async {
  while (true) {
    stdout.write('${playerName}，请选择角色（输入角色名称）: ');
    String? choice = stdin.readLineSync();
    if (choice != null && choice.isNotEmpty) {
      return choice;
    }
    print('请输入有效的角色名称');
  }
}

/// 设置初始位置
Future<void> setInitialLocations(GameEngine engine) async {
  print('\n=== 设置初始位置 ===');
  
  for (Player player in engine.gameState.players) {
    String location = await getInitialLocation(player.name);
    engine.setPlayerLocation(player, location);
  }
  
  print('初始位置设置完成！');
}

/// 获取初始位置选择
Future<String> getInitialLocation(String playerName) async {
  print('可选位置: 大厅, 卧室, 花园, 厨房, 地下室');
  
  while (true) {
    stdout.write('${playerName}，请选择初始位置: ');
    String? choice = stdin.readLineSync();
    if (choice != null && choice.isNotEmpty) {
      return choice;
    }
    print('请输入有效的位置名称');
  }
}

/// 主游戏循环
Future<void> runGameLoop(GameEngine engine) async {
  print('\n=== 游戏开始 ===');
  
  while (!engine.isGameOver()) {
    // Night phase
    await runNightPhase(engine);
    
    if (engine.isGameOver()) break;
    
    // Day phase
    await runDayPhase(engine);
  }
  
  // Show final results
  engine.showGameResults();
}

/// 夜晚阶段
Future<void> runNightPhase(GameEngine engine) async {
  print('\n=== 第${engine.gameState.currentDay}晚 ===');
  
  // Collect night actions from all players
  await collectNightActions(engine);
  
  // Process night actions in order
  engine.processNightActions();
  
  // Dawn announcement
  engine.announcedawn();
}

/// 收集夜间行动
Future<void> collectNightActions(GameEngine engine) async {
  print('请各位玩家私下告知导演夜间行动...');
  
  // In a real implementation, this would collect actions from each player
  // For now, we'll simulate with simple input
  for (Player player in engine.gameState.alivePlayers) {
    if (player.character?.canActAtNight == true) {
      await getPlayerNightAction(engine, player);
    }
  }
}

/// 获取玩家夜间行动
Future<void> getPlayerNightAction(GameEngine engine, Player player) async {
  print('\n${player.name}的回合 (${player.character?.name ?? '未知角色'})');
  print('请输入行动内容，或输入"无"跳过:');
  
  String? action = stdin.readLineSync();
  if (action != null && action != '无') {
    engine.addNightAction(player, action);
  }
}

/// 白天阶段
Future<void> runDayPhase(GameEngine engine) async {
  print('\n=== 第${engine.gameState.currentDay}天 ===');
  
  // Confirm deaths phase
  await confirmDeathsPhase(engine);
  
  // Free movement phase
  await freeMovementPhase(engine);
  
  // Voting phase
  await votingPhase(engine);
  
  // Advance to next day
  engine.advanceDay();
}

/// 确认死者阶段
Future<void> confirmDeathsPhase(GameEngine engine) async {
  print('\n--- 确认死者阶段 ---');
  
  engine.processDeathConfirmation();
  
  print('确认死者阶段结束');
}

/// 自由移动阶段
Future<void> freeMovementPhase(GameEngine engine) async {
  print('\n--- 自由移动阶段 ---');
  print('请各位自由移动');
  
  // Allow players to move
  for (Player player in engine.gameState.alivePlayers) {
    await getPlayerMovement(engine, player);
  }
  
  print('自由移动阶段结束');
}

/// 获取玩家移动
Future<void> getPlayerMovement(GameEngine engine, Player player) async {
  stdout.write('${player.name}，请输入目标位置（或输入"留下"）: ');
  String? movement = stdin.readLineSync();
  
  if (movement != null && movement != '留下') {
    engine.movePlayer(player, movement);
  }
}

/// 投票阶段
Future<void> votingPhase(GameEngine engine) async {
  print('\n--- 全体公决阶段 ---');
  print('公决开始！');
  
  Map<String, int> votes = {};
  
  // Collect votes from all alive players
  for (Player player in engine.gameState.alivePlayers) {
    String vote = await getPlayerVote(player);
    votes[vote] = (votes[vote] ?? 0) + 1;
  }
  
  // Process voting results
  engine.processVotingResults(votes);
}

/// 获取玩家投票
Future<String> getPlayerVote(Player player) async {
  stdout.write('${player.name}，请输入投票对象（或输入"弃权"）: ');
  String? vote = stdin.readLineSync();
  return vote ?? '弃权';
}