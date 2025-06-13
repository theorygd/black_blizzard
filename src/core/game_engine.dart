import 'dart:async';
import 'dart:math';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/night_action.dart';
import '../models/crime_info.dart';
import 'log_manager.dart';
import '../lang/language_manager.dart';

/// 游戏引擎核心类
/// Core game engine managing all game logic and state
class GameEngine {
  final LogManager logManager;
  final LanguageManager languageManager;
  
  late GameState gameState;
  final Random _random = Random();
  
  // Output streams for different channels
  final StreamController<String> _directorStream = StreamController<String>.broadcast();
  final Map<String, StreamController<String>> _playerStreams = {};

  GameEngine({
    required this.logManager,
    required this.languageManager,
  });

  // Stream getters for different output channels
  Stream<String> get directorOutput => _directorStream.stream;
  Stream<String> getPlayerOutput(String playerName) {
    if (!_playerStreams.containsKey(playerName)) {
      _playerStreams[playerName] = StreamController<String>.broadcast();
    }
    return _playerStreams[playerName]!.stream;
  }

  /// 初始化游戏
  void initializeGame(int playerCount) {
    gameState = GameState(playerCount: playerCount);
    _initializeLocations();
    
    logManager.log('GameEngine', 'Game initialized with $playerCount players');
    _sendToDirector('游戏初始化完成，玩家数量: $playerCount');
  }

  /// 初始化地点
  void _initializeLocations() {
    // Basic locations for all games
    gameState.locations['大厅'] = Location(
      name: '大厅',
      maxCapacity: 999, // No limit
      isDefault: true,
    );
    
    gameState.locations['卧室'] = Location(
      name: '卧室',
      maxCapacity: 3,
      specialProperties: [LocationProperty.secretRoom],
    );
    
    gameState.locations['花园'] = Location(
      name: '花园',
      maxCapacity: 4,
      specialProperties: [LocationProperty.complexTerrain],
    );
    
    gameState.locations['厨房'] = Location(
      name: '厨房',
      maxCapacity: 2,
      specialProperties: [LocationProperty.cooking],
    );
    
    gameState.locations['地下室'] = Location(
      name: '地下室',
      maxCapacity: 1,
      specialProperties: [LocationProperty.enclosedSpace],
    );

    // Additional locations based on player count
    if (gameState.playerCount >= 7) {
      gameState.locations['卫生间'] = Location(
        name: '卫生间',
        maxCapacity: 2,
        specialProperties: [LocationProperty.flowing],
      );
    }
    
    if (gameState.playerCount >= 8) {
      gameState.locations['阳台'] = Location(
        name: '阳台',
        maxCapacity: 1,
        specialProperties: [LocationProperty.scenic],
      );
    }
    
    logManager.log('GameEngine', 'Initialized ${gameState.locations.length} locations');
  }

  /// 添加玩家
  void addPlayer(String name) {
    final player = Player(
      name: name,
      actionOrder: gameState.players.length,
    );
    gameState.players.add(player);
    
    // Initialize player output stream
    _playerStreams[name] = StreamController<String>.broadcast();
    
    logManager.log('GameEngine', 'Added player: $name');
    _sendToDirector('添加玩家: $name');
  }

  /// 显示可选角色
  void showAvailableCharacters() {
    final characters = [
      '医生（女）', '医生（男）', '学生', '道具师', 
      '女驴友', '导游', '管理员', '侦探', '灵媒'
    ];
    
    _sendToDirector('可选角色: ${characters.join(', ')}');
    logManager.log('GameEngine', 'Showed available characters');
  }

  /// 分配角色
  void assignCharacter(Player player, String characterType) {
    final character = _createCharacter(characterType);
    player.character = character;
    
    logManager.log('GameEngine', 'Assigned character $characterType to ${player.name}');
    _sendToPlayer(player.name, '你的角色是: ${character.name}');
    _sendToDirector('${player.name} 选择了角色: ${character.name}');
  }

  /// 创建角色实例
  Character _createCharacter(String type) {
    switch (type) {
      case '医生（女）':
        return FemaleDoctor();
      case '医生（男）':
        return MaleDoctor();
      case '学生':
        return Student();
      case '道具师':
        return PropMaster();
      case '女驴友':
        return FemaleTraveler();
      case '导游':
        return Guide();
      case '管理员':
        return Manager();
      case '侦探':
        return Detective();
      case '灵媒':
        return Medium();
      default:
        return GenericCharacter(name: type);
    }
  }

  /// 分配特殊角色（凶手和愚者）
  void assignSpecialRoles() {
    final availablePlayers = List<Player>.from(gameState.players);
    
    // Assign murderer
    final murdererIndex = _random.nextInt(availablePlayers.length);
    final murderer = availablePlayers[murdererIndex];
    murderer.isMurderer = true;
    gameState.murderer = murderer;
    
    // Remove murderer from available list
    availablePlayers.removeAt(murdererIndex);
    
    // Assign fool
    final foolIndex = _random.nextInt(availablePlayers.length);
    final fool = availablePlayers[foolIndex];
    fool.isFool = true;
    gameState.fool = fool;
    
    logManager.log('GameEngine', 'Assigned murderer: ${murderer.name}');
    logManager.log('GameEngine', 'Assigned fool: ${fool.name}');
    
    _sendToPlayer(murderer.name, '你是凶手！');
    _sendToDirector('凶手: ${murderer.name}, 愚者: ${fool.name}');
  }

  /// 设置玩家位置
  void setPlayerLocation(Player player, String locationName) {
    final location = gameState.locations[locationName];
    if (location == null) {
      _sendToDirector('错误：未知位置 $locationName');
      return;
    }
    
    if (!location.canAccommodate()) {
      // Move to default location (大厅)
      player.currentLocation = gameState.locations['大厅']!;
      _sendToDirector('${player.name} 位置已满，被传送至大厅');
    } else {
      player.currentLocation = location;
      location.addPlayer(player);
    }
    
    logManager.log('GameEngine', '${player.name} moved to ${player.currentLocation.name}');
    _sendToPlayer(player.name, '你现在在: ${player.currentLocation.name}');
  }

  /// 添加夜间行动
  void addNightAction(Player player, String action) {
    final nightAction = NightAction(
      player: player,
      action: action,
      actionOrder: _getNightActionOrder(player),
    );
    
    gameState.nightActions.add(nightAction);
    
    logManager.log('GameEngine', '${player.name} night action: $action');
    _sendToPlayer(player.name, '夜间行动已记录');
  }

  /// 获取夜间行动顺序
  int _getNightActionOrder(Player player) {
    // Order: 灵媒-学生-男医生-道具师-女医生-女驴友-导游-管理员-凶手-侦探
    final orderMap = {
      '灵媒': 0,
      '学生': 1,
      '医生（男）': 2,
      '道具师': 3,
      '医生（女）': 4,
      '女驴友': 5,
      '导游': 6,
      '管理员': 7,
      '侦探': 9,
    };
    
    final characterName = player.character?.name ?? '';
    
    if (player.isMurderer) {
      return 8; // Murderer always goes 8th
    }
    
    return orderMap[characterName] ?? 10;
  }

  /// 处理夜间行动
  void processNightActions() {
    // Sort actions by order
    gameState.nightActions.sort((a, b) => a.actionOrder.compareTo(b.actionOrder));
    
    _sendToDirector('开始处理夜间行动...');
    
    for (final action in gameState.nightActions) {
      if (action.player.isAlive) {
        _processIndividualNightAction(action);
      }
    }
    
    // Clear night actions for next night
    gameState.nightActions.clear();
    
    logManager.log('GameEngine', 'Processed all night actions');
  }

  /// 处理单个夜间行动
  void _processIndividualNightAction(NightAction action) {
    final player = action.player;
    final character = player.character;
    
    if (character != null) {
      character.performNightAction(this, action);
    }
    
    // Special handling for murderer
    if (player.isMurderer) {
      _processMurderAction(action);
    }
  }

  /// 处理谋杀行动
  void _processMurderAction(NightAction action) {
    // Parse murder plan from action
    // This would be more complex in reality
    final parts = action.action.split('|');
    if (parts.length >= 3) {
      final method = parts[0];
      final target = parts[1];
      final clue = parts[2];
      
      _executeMurderPlan(action.player, method, target, clue);
    }
  }

  /// 执行谋杀计划
  void _executeMurderPlan(Player murderer, String method, String target, String clue) {
    // Find target player or location
    Player? targetPlayer;
    Location? targetLocation;
    
    // Try to find target player
    for (final player in gameState.alivePlayers) {
      if (player.name == target) {
        targetPlayer = player;
        break;
      }
    }
    
    // Try to find target location
    if (targetPlayer == null) {
      targetLocation = gameState.locations[target];
    }
    
    bool murderSuccessful = false;
    String crimeLocation = '';
    
    if (targetPlayer != null) {
      // Individual murder
      murderSuccessful = _attemptIndividualMurder(murderer, targetPlayer, method);
      crimeLocation = targetPlayer.currentLocation.name;
    } else if (targetLocation != null) {
      // Location murder
      murderSuccessful = _attemptLocationMurder(murderer, targetLocation, method);
      crimeLocation = targetLocation.name;
    }
    
    if (murderSuccessful) {
      _createCrimeInfo(crimeLocation, method, clue);
      gameState.murderSuccessfulThisNight = true;
    } else {
      // Failed murder - clue still appears at crime location
      _addExtraClue(crimeLocation, clue);
    }
    
    logManager.log('GameEngine', 'Murder attempt: ${murderSuccessful ? 'successful' : 'failed'}');
  }

  /// 尝试个人谋杀
  bool _attemptIndividualMurder(Player murderer, Player target, String method) {
    // Check if target can be murdered
    if (!target.isAlive) return false;
    
    // Special protections (e.g., basement)
    if (target.currentLocation.name == '地下室' && method != '指定死者') {
      return false;
    }
    
    // Kill the target
    target.isAlive = false;
    target.deathMethod = method;
    target.deathLocation = target.currentLocation;
    
    gameState.deadPlayers.add(target);
    
    _sendToDirector('${target.name} 被杀死在 ${target.currentLocation.name}');
    
    return true;
  }

  /// 尝试地点谋杀
  bool _attemptLocationMurder(Player murderer, Location location, String method) {
    final targets = location.players.where((p) => p.isAlive).toList();
    
    if (targets.isEmpty) return false;
    
    // Kill all players in the location
    for (final target in targets) {
      target.isAlive = false;
      target.deathMethod = method;
      target.deathLocation = location;
      gameState.deadPlayers.add(target);
    }
    
    _sendToDirector('${targets.length}人 被杀死在 ${location.name}');
    
    return true;
  }

  /// 创建犯罪信息
  void _createCrimeInfo(String location, String method, String clue) {
    final crimeInfo = CrimeInfo(
      location: location,
      deathCause: method,
      clue: clue,
      victims: gameState.deadPlayers.where((p) => p.deathLocation?.name == location).toList(),
    );
    
    final loc = gameState.locations[location];
    if (loc != null) {
      loc.crimeInfo = crimeInfo;
    }
    
    logManager.log('GameEngine', 'Created crime info at $location');
  }

  /// 添加额外线索
  void _addExtraClue(String locationName, String clue) {
    final location = gameState.locations[locationName];
    if (location != null) {
      location.extraClues.add(clue);
    }
  }

  /// 宣布黎明
  void announceDawn() {
    _sendToDirector('=== 天亮了 ===');
    
    // Show all player locations
    _sendToDirector('各位玩家位置:');
    for (final player in gameState.alivePlayers) {
      _sendToDirector('${player.name}: ${player.currentLocation.name}');
    }
    
    // Check for murderer tracks
    if (gameState.murdererTracksActive && 
        !gameState.murderSuccessfulThisNight &&
        _hasSurvivorsAtMurdererLocation()) {
      _sendToDirector('昨晚有人发现了凶手行踪');
    }
    
    logManager.log('GameEngine', 'Dawn announced for day ${gameState.currentDay}');
  }

  /// 检查凶手位置是否有幸存者
  bool _hasSurvivorsAtMurdererLocation() {
    if (gameState.murderer == null) return false;
    
    final murdererLocation = gameState.murderer!.currentLocation;
    return murdererLocation.players.any((p) => p.isAlive && p != gameState.murderer);
  }

  /// 处理死者确认
  void processDeathConfirmation() {
    for (final location in gameState.locations.values) {
      if (location.crimeInfo != null && location.players.any((p) => p.isAlive)) {
        // Players at this location get crime info
        for (final player in location.players.where((p) => p.isAlive)) {
          _giveCrimeInfoToPlayer(player, location.crimeInfo!);
        }
        
        // Crime info disappears after being discovered
        location.crimeInfo = null;
      }
    }
  }

  /// 向玩家提供犯罪信息
  void _giveCrimeInfoToPlayer(Player player, CrimeInfo crimeInfo) {
    String info = '犯罪信息:\n';
    info += '地点: ${crimeInfo.location}\n';
    info += '死因: ${crimeInfo.deathCause}\n';
    info += '线索: ${crimeInfo.clue}\n';
    info += '死者: ${crimeInfo.victims.map((v) => v.name).join(', ')}';
    
    if (player.isFool) {
      // Fool gets false information
      info = '诡计信息:\n伪造的犯罪现场信息';
    }
    
    _sendToPlayer(player.name, info);
    
    // Check if this activates murderer tracks
    if (!gameState.murdererTracksActive) {
      _sendToPlayer(player.name, '是否激活凶手行踪追踪？(y/n)');
      // In real implementation, wait for response
      gameState.murdererTracksActive = true;
    }
  }

  /// 移动玩家
  void movePlayer(Player player, String locationName) {
    final targetLocation = gameState.locations[locationName];
    if (targetLocation == null) {
      _sendToPlayer(player.name, '错误：未知位置');
      return;
    }
    
    // Remove from current location
    player.currentLocation.removePlayer(player);
    
    // Try to move to target location
    if (targetLocation.canAccommodate()) {
      player.currentLocation = targetLocation;
      targetLocation.addPlayer(player);
      
      // Check for crime info and extra clues
      if (targetLocation.crimeInfo != null) {
        _giveCrimeInfoToPlayer(player, targetLocation.crimeInfo!);
        targetLocation.crimeInfo = null;
      }
      
      // Check for extra clues (敏锐 trait)
      if (player.character?.hasAcuteTrait == true && targetLocation.extraClues.isNotEmpty) {
        _sendToPlayer(player.name, '发现额外线索: ${targetLocation.extraClues.join(', ')}');
        targetLocation.extraClues.clear();
      }
      
      _sendToPlayer(player.name, '移动成功，现在在: ${targetLocation.name}');
    } else {
      // Move to default location
      final defaultLocation = gameState.locations['大厅']!;
      player.currentLocation = defaultLocation;
      defaultLocation.addPlayer(player);
      _sendToPlayer(player.name, '目标位置已满，被传送至大厅');
    }
    
    logManager.log('GameEngine', '${player.name} moved to ${player.currentLocation.name}');
  }

  /// 处理投票结果
  void processVotingResults(Map<String, int> votes) {
    // Remove abstentions
    votes.remove('弃权');
    
    if (votes.isEmpty) {
      _sendToDirector('公决失败：所有人弃权');
      return;
    }
    
    // Find the player with most votes
    String? votedOutPlayer;
    int maxVotes = 0;
    
    for (final entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        votedOut