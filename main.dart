/// Black Blizzard - Main Game Controller
/// 暴风雪山庄主程序 - 游戏控制器
library black_blizzard;

import 'dart:async';
import 'dart:math';

// Parts of the game system
part 'game_state.dart';
part 'player.dart';
part 'location_base.dart';
part 'character.dart';
part 'log.dart';

// Sub-parts for complex player-related systems
part 'killer_system.dart';
part 'action_system.dart';
part 'location_lobby.dart';
part 'location_bedroom.dart';
part 'location_basement.dart';
part 'location_kitchen.dart';
part 'location_garden.dart';
part 'location_bathroom.dart';
part 'location_balcony.dart';
part 'location_effect.dart';

/// Main game controller class
/// 主游戏控制器类
class BlizzardManor {
  static BlizzardManor? _instance;
  
  // Game configuration
  late int _playerCount;
  late int _dayCount;
  late List<String> _availableLocations;
  
  // Game state
  late GameState _gameState;
  late List<Player> _players;
  late Map<String, Location> _locations;
  late Random _random;
  
  // Streams for different output channels
  late StreamController<String> _directorChannel;
  late StreamController<String> _publicChannel;
  late Map<String, StreamController<String>> _playerChannels;
  
  // Singleton pattern
  factory BlizzardManor() {
    _instance ??= BlizzardManor._internal();
    return _instance!;
  }
  
  BlizzardManor._internal() {
    _random = Random();
    _directorChannel = StreamController<String>.broadcast();
    _publicChannel = StreamController<String>.broadcast();
    _playerChannels = {};
    Log.instance.record('Game system initialized');
  }
  
  /// Initialize game with specified player count
  /// 初始化游戏，指定玩家数量
  void initializeGame(int playerCount) {
    Log.instance.record('Initializing game with $playerCount players');
    
    _playerCount = playerCount;
    _setupGameConfiguration();
    _initializeLocations();
    _gameState = GameState();
    _players = [];
    
    _sendToDirector('游戏系统已初始化，玩家数量：$_playerCount');
    Log.instance.record('Game initialization completed');
  }
  
  /// Setup game configuration based on player count
  /// 根据玩家数量设置游戏配置
  void _setupGameConfiguration() {
    // Basic locations
    _availableLocations = ['大厅', '卧室', '地下室', '厨房', '花园'];
    _dayCount = 3;
    
    // Additional locations and days based on player count
    if (_playerCount >= 7) {
      _availableLocations.add('卫生间');
      _dayCount = 4;
    }
    if (_playerCount >= 8) {
      _availableLocations.add('阳台');
    }
    
    Log.instance.record('Game configured: $_dayCount days, locations: $_availableLocations');
  }
  
  /// Initialize all game locations
  /// 初始化所有游戏地点
  void _initializeLocations() {
    _locations = {};
    
    // Create locations with their specific properties
    _locations['大厅'] = Location('大厅', isDefault: true, capacity: 999);
    _locations['卧室'] = Location('卧室', capacity: 3);
    _locations['地下室'] = Location('地下室', capacity: 1);
    _locations['厨房'] = Location('厨房', capacity: 2);
    _locations['花园'] = Location('花园', capacity: 4);
    
    if (_availableLocations.contains('卫生间')) {
      _locations['卫生间'] = Location('卫生间', capacity: 2);
    }
    if (_availableLocations.contains('阳台')) {
      _locations['阳台'] = Location('阳台', capacity: 1);
    }
    
    Log.instance.record('Locations initialized: ${_locations.keys.join(', ')}');
  }
  
  /// Register a new player in the game
  /// 注册新玩家
  void registerPlayer(String playerId, String playerName) {
    if (_players.length >= _playerCount) {
      _sendToDirector('错误：玩家数量已达上限');
      return;
    }
    
    var player = Player(playerId, playerName);
    _players.add(player);
    
    // Create player channel
    _playerChannels[playerId] = StreamController<String>.broadcast();
    
    _sendToDirector('玩家已注册：$playerName ($playerId)');
    _sendToPublic('玩家 $playerName 加入了游戏');
    Log.instance.record('Player registered: $playerName ($playerId)');
  }
  
  /// Assign character to player
  /// 为玩家分配角色
  void assignCharacter(String playerId, String characterType) {
    var player = _getPlayer(playerId);
    if (player == null) {
      _sendToDirector('错误：未找到玩家 $playerId');
      return;
    }
    
    // Check if character type is already taken
    if (_players.any((p) => p.character?.type == characterType)) {
      _sendToDirector('错误：角色 $characterType 已被选择');
      return;
    }
    
    var character = CharacterFactory.createCharacter(characterType);
    if (character == null) {
      _sendToDirector('错误：未知角色类型 $characterType');
      return;
    }
    
    player.assignCharacter(character);
    _sendToDirector('玩家 ${player.name} 选择了角色：$characterType');
    Log.instance.record('Character assigned: ${player.name} -> $characterType');
  }
  
  /// Start the game
  /// 开始游戏
  void startGame() {
    if (_players.length < 6) {
      _sendToDirector('错误：至少需要6名玩家才能开始游戏');
      return;
    }
    
    if (_players.any((p) => p.character == null)) {
      _sendToDirector('错误：所有玩家都必须选择角色');
      return;
    }
    
    _assignSpecialRoles();
    _setInitialPositions();
    _gameState.startGame(_dayCount);
    
    _sendToPublic('游戏开始！暴风雪即将来临...');
    _sendToDirector('游戏已开始，当前阶段：${_gameState.currentPhase}');
    Log.instance.record('Game started');
    
    _processNightPhase();
  }
  
  /// Assign special roles (killer and fool)
  /// 分配特殊身份（凶手和愚者）
  void _assignSpecialRoles() {
    // Randomly select killer
    var killerIndex = _random.nextInt(_players.length);
    _players[killerIndex].assignKiller();
    
    // Randomly select fool from remaining players
    var remainingPlayers = List<Player>.from(_players);
    remainingPlayers.removeAt(killerIndex);
    var foolIndex = _random.nextInt(remainingPlayers.length);
    remainingPlayers[foolIndex].assignFool();
    
    _sendToDirector('特殊身份已分配完成');
    _sendToPlayer(_players[killerIndex].id, '你是凶手！你的目标是制造命案并嫁祸他人。');
    Log.instance.record('Special roles assigned: killer and fool selected');
  }
  
  /// Set initial positions for all players
  /// 设置所有玩家的初始位置
  void _setInitialPositions() {
    for (var player in _players) {
      _sendToPlayer(player.id, '请选择你的初始位置：${_availableLocations.join('、')}');
    }
    Log.instance.record('Initial position selection started');
  }
  
  /// Process night phase actions
  /// 处理夜晚阶段行动
  void _processNightPhase() {
    _sendToPublic('夜幕降临，请所有人提交夜间行动...');
    _sendToDirector('夜间阶段开始，等待玩家行动');
    Log.instance.record('Night phase started');
  }
  
  // Channel communication methods
  /// 发送消息给导演
  void _sendToDirector(String message) {
    _directorChannel.add('[导演] $message');
  }
  
  /// 发送公共消息
  void _sendToPublic(String message) {
    _publicChannel.add('[公告] $message');
  }
  
  /// 发送私人消息给玩家
  void _sendToPlayer(String playerId, String message) {
    var channel = _playerChannels[playerId];
    if (channel != null) {
      channel.add('[私人] $message');
    }
  }
  
  /// 获取玩家对象
  Player? _getPlayer(String playerId) {
    try {
      return _players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }
  
  // Stream getters for external access
  Stream<String> get directorStream => _directorChannel.stream;
  Stream<String> get publicStream => _publicChannel.stream;
  Stream<String> getPlayerStream(String playerId) {
    return _playerChannels[playerId]?.stream ?? Stream.empty();
  }
  
  /// Dispose resources
  /// 释放资源
  void dispose() {
    _directorChannel.close();
    _publicChannel.close();
    for (var channel in _playerChannels.values) {
      channel.close();
    }
    Log.instance.record('Game system disposed');
  }
}

/// Example usage and testing
/// 使用示例和测试
void main() {
  var game = BlizzardManor();
  
  // Set up listeners
  game.directorStream.listen((message) => print('导演频道: $message'));
  game.publicStream.listen((message) => print('公共频道: $message'));
  
  // Initialize and start a test game
  game.initializeGame(6);
  
  // Register test players
  for (int i = 1; i <= 6; i++) {
    game.registerPlayer('player$i', '玩家$i');
    
    // Set up player stream listener
    game.getPlayerStream('player$i').listen((message) => 
        print('玩家$i频道: $message'));
  }
  
  // Assign characters (simplified for testing)
  game.assignCharacter('player1', '医生');
  
  print('暴风雪山庄游戏系统测试完成');
}