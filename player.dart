/// Player System for Black Blizzard
/// 暴风雪山庄玩家系统
part of black_blizzard;

/// Represents a player in the game
/// 游戏中的玩家
class Player {
  final String id;
  final String name;
  
  // Player state
  Character? character;
  String? currentLocation;
  bool isAlive = true;
  bool isKiller = false;
  bool isFool = false;
  
  // Movement and action tracking
  int normalMoveCount = 0;
  int extraMoveCount = 0;
  List<String> actionHistory = [];
  
  // Information and clues
  List<CrimeInfo> crimeInfos = [];
  List<String> clues = [];
  List<String> extraClues = [];
  
  // Night action state
  PlayerAction? pendingNightAction;
  bool hasSubmittedNightAction = false;
  
  Player(this.id, this.name) {
    Log.instance.record('Player created: $name ($id)');
  }
  
  /// Assign character to this player
  /// 为玩家分配角色
  void assignCharacter(Character newCharacter) {
    character = newCharacter;
    character?.owner = this;
    Log.instance.record('Character assigned to ${name}: ${character?.type}');
  }
  
  /// Assign killer role to this player
  /// 指定玩家为凶手
  void assignKiller() {
    isKiller = true;
    // Initialize killer-specific data
    var killerData = KillerSystem(this);
    character?.killerData = killerData;
    Log.instance.record('Player $name assigned as killer');
  }
  
  /// Assign fool role to this player
  /// 指定玩家为愚者
  void assignFool() {
    isFool = true;
    Log.instance.record('Player $name assigned as fool');
  }
  
  /// Move player to a location
  /// 移动玩家到指定地点
  bool moveToLocation(String locationName, {bool useExtraMove = false}) {
    var game = BlizzardManor();
    var targetLocation = game._locations[locationName];
    
    if (targetLocation == null) {
      Log.instance.record('Move failed: invalid location $locationName for $name');
      return false;
    }
    
    // Check if player has moves available
    int availableMoves = useExtraMove ? extraMoveCount : normalMoveCount;
    if (availableMoves <= 0) {
      game._sendToPlayer(id, '你没有足够的移动次数');
      Log.instance.record('Move failed: no moves available for $name');
      return false;
    }
    
    // Try to move to location
    bool moveSuccess = targetLocation.addPlayer(this);
    
    if (moveSuccess) {
      // Remove from current location
      if (currentLocation != null) {
        var currentLoc = game._locations[currentLocation!];
        currentLoc?.removePlayer(this);
      }
      
      // Update player location
      currentLocation = locationName;
      
      // Consume move count
      if (useExtraMove) {
        extraMoveCount--;
      } else {
        normalMoveCount--;
      }
      
      // Trigger location effects and abilities
      _handleLocationEntry(targetLocation);
      
      game._sendToPlayer(id, '你成功移动到了$locationName');
      Log.instance.record('Player $name moved to $locationName');
      return true;
    } else {
      // Location full, move to default location
      var defaultLocation = game._locations['大厅']!;
      defaultLocation.addPlayer(this);
      
      if (currentLocation != null) {
        var currentLoc = game._locations[currentLocation!];
        currentLoc?.removePlayer(this);
      }
      
      currentLocation = '大厅';
      
      // Still consume move count
      if (useExtraMove) {
        extraMoveCount--;
      } else {
        normalMoveCount--;
      }
      
      // Don't notify player of the forced move (as per rules)
      Log.instance.record('Player $name forced to default location (target full)');
      return false;
    }
  }
  
  /// Handle effects when entering a location
  /// 处理进入地点时的效果
  void _handleLocationEntry(Location location) {
    // Get crime information if available
    if (location.crimeInfos.isNotEmpty) {
      crimeInfos.addAll(location.crimeInfos);
      location.crimeInfos.clear();
      
      var game = BlizzardManor();
      game._sendToPlayer(id, '你发现了犯罪信息！');
      for (var info in crimeInfos) {
        if (!isFool) {
          game._sendToPlayer(id, info.getDisplayText());
        } else {
          // Fool gets fake information
          game._sendToPlayer(id, info.getFakeDisplayText());
        }
      }
    }
    
    // Trigger character abilities
    character?.onLocationEntry(location);
    
    // Handle敏锐 ability
    if (character?.hasAbility('敏锐') == true && location.extraClues.isNotEmpty) {
      extraClues.addAll(location.extraClues);
      location.extraClues.clear();
      
      var game = BlizzardManor();
      game._sendToPlayer(id, '你的敏锐让你发现了额外线索！');
    }
  }
  
  /// Submit night action
  /// 提交夜间行动
  void submitNightAction(PlayerAction action) {
    if (hasSubmittedNightAction) {
      var game = BlizzardManor();
      game._sendToPlayer(id, '你已经提交过夜间行动了');
      return;
    }
    
    pendingNightAction = action;
    hasSubmittedNightAction = true;
    
    var game = BlizzardManor();
    game._sendToPlayer(id, '夜间行动已提交');
    game._sendToDirector('玩家 $name 已提交夜间行动');
    Log.instance.record('Night action submitted by $name: ${action.type}');
  }
  
  /// Process night action during resolution
  /// 在结算阶段处理夜间行动
  void processNightAction() {
    if (pendingNightAction == null || !isAlive) {
      return;
    }
    
    var action = pendingNightAction!;
    Log.instance.record('Processing night action for $name: ${action.type}');
    
    switch (action.type) {
      case ActionType.move:
        _processMoveAction(action);
        break;
      case ActionType.useSkill:
        _processSkillAction(action);
        break;
      case ActionType.kill:
        if (isKiller) {
          _processKillAction(action);
        }
        break;
      default:
        Log.instance.record('Unknown action type: ${action.type}');
    }
    
    // Clear action after processing
    pendingNightAction = null;
  }
  
  /// Process movement action
  /// 处理移动行动
  void _processMoveAction(PlayerAction action) {
    if (action.targetLocation != null) {
      moveToLocation(action.targetLocation!);
    }
  }
  
  /// Process skill usage action
  /// 处理技能使用行动
  void _processSkillAction(PlayerAction action) {
    character?.useSkill(action.skillName, action.parameters);
  }
  
  /// Process kill action (killer only)
  /// 处理杀人行动（仅凶手）
  void _processKillAction(PlayerAction action) {
    if (!isKiller || character?.killerData == null) {
      return;
    }
    
    character!.killerData!.executeKillPlan(action);
  }
  
  /// Reset daily counters
  /// 重置每日计数器
  void resetDailyCounters() {
    normalMoveCount = 1; // Each player gets 1 normal move per day
    hasSubmittedNightAction = false;
    pendingNightAction = null;
    
    // Reset character daily abilities
    character?.resetDailyAbilities();
    
    Log.instance.record('Daily counters reset for $name');
  }
  
  /// Add extra move count
  /// 增加额外移动次数
  void addExtraMove(int count) {
    extraMoveCount += count;
    Log.instance.record('Added $count extra moves to $name');
  }
  
  /// Kill this player
  /// 杀死该玩家
  void kill(String cause, String location) {
    if (!isAlive) return;
    
    isAlive = false;
    var game = BlizzardManor();
    
    // Trigger character death abilities
    character?.onDeath(cause, location);
    
    game._sendToPlayer(id, '你已经死亡了...');
    game._sendToDirector('玩家 $name 在 $location 死亡，死因：$cause');
    Log.instance.record('Player $name killed: $cause at $location');
  }
  
  /// Get player status summary
  /// 获取玩家状态摘要
  Map<String, dynamic> getStatusSummary() {
    return {
      'id': id,
      'name': name,
      'character': character?.type,
      'location': currentLocation,
      'isAlive': isAlive,
      'isKiller': isKiller,
      'isFool': isFool,
      'normalMoves': normalMoveCount,
      'extraMoves': extraMoveCount,
      'hasNightAction': hasSubmittedNightAction,
      'crimeInfoCount': crimeInfos.length,
      'clueCount': clues.length + extraClues.length,
    };
  }
  
  /// Display info for director
  /// 为导演显示信息
  String getDirectorInfo() {
    var status = getStatusSummary();
    var roleInfo = '';
    if (isKiller) roleInfo += '[凶手] ';
    if (isFool) roleInfo += '[愚者] ';
    
    return '玩家：${status['name']} $roleInfo'
           '- 角色：${status['character']} '
           '- 位置：${status['location']} '
           '- 状态：${status['isAlive'] ? '存活' : '死亡'} '
           '- 移动：${status['normalMoves']}+${status['extraMoves']} '
           '- 夜间行动：${status['hasNightAction'] ? '已提交' : '未提交'}';
  }
}

/// Represents crime information discovered by players
/// 玩家发现的犯罪信息
class CrimeInfo {
  final String victim;
  final String location;
  final String cause;
  final String clue;
  final bool isComplete;
  
  CrimeInfo(this.victim, this.location, this.cause, this.clue, {this.isComplete = true});
  
  /// Get display text for normal players
  /// 获得普通玩家的显示文本
  String getDisplayText() {
    return '犯罪信息：死者-$victim，地点-$location，死因-$cause，线索-$clue';
  }
  
  /// Get fake display text for fool
  /// 获得愚者的虚假显示文本
  String getFakeDisplayText() {
    // This would contain the fake information set by killer's trick
    return '犯罪信息：死者-$victim，地点-$location，死因-$cause，线索-$clue';
  }
}