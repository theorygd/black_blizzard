/// Killer System for Black Blizzard
/// 暴风雪山庄凶手系统
part of black_blizzard;

/// Killer-specific data and behavior
/// 凶手专属数据和行为
class KillerSystem {
  final Player owner;
  
  // Killer configuration
  String? motive; // 犯罪动机
  List<String> availableMethods = []; // 可用杀人手法
  List<String> availableClues = []; // 可用线索
  Map<String, int> methodUsageCount = {}; // 手法使用次数统计
  
  // Kill plan for current night
  KillPlan? currentPlan;
  bool hasKilledSuccessfully = false;
  
  KillerSystem(this.owner) {
    _initializeKillerData();
    Log.instance.record('Killer system initialized for ${owner.name}');
  }
  
  /// Initialize killer-specific data
  /// 初始化凶手专属数据
  void _initializeKillerData() {
    // Assign random motive
    _assignRandomMotive();
    
    // Initialize basic kill methods and clues from character
    if (owner.character != null) {
      availableMethods = List.from(owner.character!.killMethods);
      availableClues = List.from(owner.character!.clues);
    }
    
    // Apply motive effects
    _applyMotiveEffects();
  }
  
  /// Assign random criminal motive
  /// 分配随机犯罪动机
  void _assignRandomMotive() {
    var motives = ['愉悦', '预谋', '献祭', '迷梦'];
    var random = Random();
    motive = motives[random.nextInt(motives.length)];
    
    var game = BlizzardManor();
    game._sendToPlayer(owner.id, '你的犯罪动机是：$motive');
    Log.instance.record('Killer motive assigned: $motive');
  }
  
  /// Apply motive-specific effects
  /// 应用动机特定效果
  void _applyMotiveEffects() {
    switch (motive) {
      case '愉悦':
        // 愉悦动机：行凶成功后可选择移动至作案地点
        break;
      case '预谋':
        // 预谋动机：游戏开始时获得额外线索或手法
        _addPremeditationBonus();
        break;
      case '献祭':
        // 献祭动机：夜间可选择获得所在地点额外线索
        break;
      case '迷梦':
        // 迷梦动机：获知所有愚者名单
        _revealFools();
        break;
    }
  }
  
  /// Add premeditation bonus (extra clue or method)
  /// 添加预谋奖励（额外线索或手法）
  void _addPremeditationBonus() {
    var random = Random();
    var bonusOptions = ['刀杀', '钝击', '绞杀'];
    var extraClues = ['痕迹：血迹', '痕迹：指纹', '遗留物：纤维'];
    
    if (random.nextBool()) {
      // Add extra method
      var extraMethod = bonusOptions[random.nextInt(bonusOptions.length)];
      if (!availableMethods.contains(extraMethod)) {
        availableMethods.add(extraMethod);
      }
    } else {
      // Add extra clue
      var extraClue = extraClues[random.nextInt(extraClues.length)];
      if (!availableClues.contains(extraClue)) {
        availableClues.add(extraClue);
      }
    }
    
    var game = BlizzardManor();
    game._sendToPlayer(owner.id, '预谋动机为你提供了额外的杀人工具');
    Log.instance.record('Premeditation bonus applied');
  }
  
  /// Reveal all fools to killer
  /// 向凶手揭示所有愚者
  void _revealFools() {
    var game = BlizzardManor();
    var fools = game._players.where((p) => p.isFool).toList();
    
    if (fools.isNotEmpty) {
      var foolNames = fools.map((f) => f.name).join('、');
      game._sendToPlayer(owner.id, '迷梦动机让你知道了愚者：$foolNames');
      Log.instance.record('Fools revealed to killer: $foolNames');
    }
  }
  
  /// Submit kill plan for the night
  /// 提交当晚的杀人计划
  void submitKillPlan(String method, String targetType, 
                     String targetValue, String clue,
                     {String? trickMethod, String? trickClue}) {
    // Validate kill method
    if (!availableMethods.contains(method)) {
      var game = BlizzardManor();
      game._sendToPlayer(owner.id, '错误：你没有 $method 这种杀人手法');
      return;
    }
    
    // Check for consecutive same method usage
    if (_wasMethodUsedLastNight(method)) {
      var game = BlizzardManor();
      game._sendToPlayer(owner.id, '错误：不能连续两晚使用相同的杀人手法');
      return;
    }
    
    // Validate clue
    if (!availableClues.contains(clue)) {
      var game = BlizzardManor();
      game._sendToPlayer(owner.id, '错误：你没有 $clue 这个线索');
      return;
    }
    
    // Create kill plan
    currentPlan = KillPlan(
      method: method,
      targetType: targetType, // 'player' or 'location'
      targetValue: targetValue,
      clue: clue,
      trickMethod: trickMethod,
      trickClue: trickClue,
    );
    
    var game = BlizzardManor();
    game._sendToPlayer(owner.id, '杀人计划已提交');
    game._sendToDirector('凶手已提交杀人计划');
    Log.instance.record('Kill plan submitted: $method -> $targetValue');
  }
  
  /// Check if method was used last night
  /// 检查昨晚是否使用了该手法
  bool _wasMethodUsedLastNight(String method) {
    // This would check the game history - simplified for now
    return false;
  }
  
  /// Execute the kill plan
  /// 执行杀人计划
  void executeKillPlan(PlayerAction action) {
    if (currentPlan == null) {
      Log.instance.record('No kill plan to execute');
      return;
    }
    
    var plan = currentPlan!;
    var game = BlizzardManor();
    
    Log.instance.record('Executing kill plan: ${plan.method} -> ${plan.targetValue}');
    
    bool killSuccess = false;
    List<Player> victims = [];
    String crimeLocation = owner.currentLocation ?? '未知地点';
    
    if (plan.targetType == 'player') {
      // Target specific player
      killSuccess = _executePlayerKill(plan, victims);
    } else if (plan.targetType == 'location') {
      // Target location (group kill)
      killSuccess = _executeLocationKill(plan, victims, crimeLocation);
    }
    
    // Record method usage
    methodUsageCount[plan.method] = (methodUsageCount[plan.method] ?? 0) + 1;
    
    // Handle kill results
    if (killSuccess && victims.isNotEmpty) {
      hasKilledSuccessfully = true;
      _createCrimeScene(victims, crimeLocation, plan);
      
      // Apply motive-specific effects
      if (motive == '愉悦') {
        _handlePleasureMotiveEffect(crimeLocation);
      }
      
      game._sendToPlayer(owner.id, '行凶成功！');
      game._sendToDirector('凶手行凶成功，受害者：${victims.map((v) => v.name).join('、')}');
    } else {
      // Kill failed
      _handleFailedKill(plan, crimeLocation);
      game._sendToPlayer(owner.id, '行凶失败...');
      game._sendToDirector('凶手行凶失败');
    }
    
    // Remove used clue
    availableClues.remove(plan.clue);
    currentPlan = null;
  }
  
  /// Execute kill targeting specific player
  /// 执行针对特定玩家的杀人
  bool _executePlayerKill(KillPlan plan, List<Player> victims) {
    var game = BlizzardManor();
    var target = game._players.where((p) => p.name == plan.targetValue).firstOrNull;
    
    if (target == null || !target.isAlive) {
      return false;
    }
    
    // Check special protections
    if (_isPlayerProtected(target, plan)) {
      return false;
    }
    
    // Execute kill
    target.kill(plan.method, target.currentLocation ?? '未知地点');
    victims.add(target);
    
    return true;
  }
  
  /// Execute kill targeting location
  /// 执行针对地点的杀人
  bool _executeLocationKill(KillPlan plan, List<Player> victims, String crimeLocation) {
    var game = BlizzardManor();
    var targetLocation = game._locations[plan.targetValue];
    
    if (targetLocation == null) {
      return false;
    }
    
    // Check if location allows group kills
    if (!_canGroupKillAtLocation(targetLocation, plan)) {
      return false;
    }
    
    // Kill all players at location
    var playersAtLocation = List<Player>.from(targetLocation.players);
    for (var player in playersAtLocation) {
      if (player.isAlive && player != owner) {
        if (!_isPlayerProtected(player, plan)) {
          player.kill(plan.method, plan.targetValue);
          victims.add(player);
        }
      }
    }
    
    crimeLocation = plan.targetValue;
    return victims.isNotEmpty;
  }
  
  /// Check if player is protected from kill
  /// 检查玩家是否受到保护
  bool _isPlayerProtected(Player target, KillPlan plan) {
    // Check character-specific protections
    if (target.character?.hasAbility('善战') == true && plan.targetType == 'player') {
      // 善战 ability: requires extra clue when killed by指杀
      _addExtraClueToLocation(target.currentLocation ?? owner.currentLocation ?? '大厅');
    }
    
    return false; // No absolute protection in base rules
  }
  
  /// Check if group kill is allowed at location
  /// 检查是否允许在该地点进行群杀
  bool _canGroupKillAtLocation(Location location, KillPlan plan) {
    // 花园 cannot be targeted for group kills
    if (location.name == '花园') {
      return false;
    }
    
    // Some methods might have location restrictions
    return true;
  }
  
  /// Create crime scene with evidence
  /// 创建犯罪现场和证据
  void _createCrimeScene(List<Player> victims, String location, KillPlan plan) {
    var game = BlizzardManor();
    var crimeLocation = game._locations[location];
    
    if (crimeLocation == null) return;
    
    // Create crime information for each victim
    for (var victim in victims) {
      var crimeInfo = CrimeInfo(
        victim.name,
        location,
        plan.method,
        plan.clue,
      );
      
      crimeLocation.crimeInfos.add(crimeInfo);
    }
    
    Log.instance.record('Crime scene created at $location with ${victims.length} victims');
  }
  
  /// Handle failed kill attempt
  /// 处理失败的杀人尝试
  void _handleFailedKill(KillPlan plan, String location) {
    var game = BlizzardManor();
    var crimeLocation = game._locations[location];
    
    // Failed kill still leaves the intended clue as extra clue
    if (crimeLocation != null) {
      crimeLocation.extraClues.add(plan.clue);
    }
    
    Log.instance.record('Failed kill attempt, clue left at $location');
  }
  
  /// Handle pleasure motive effect after successful kill
  /// 处理愉悦动机在成功杀人后的效果
  void _handlePleasureMotiveEffect(String crimeLocation) {
    var game = BlizzardManor();
    game._sendToPlayer(owner.id, '愉悦动机触发：你可以选择移动到作案地点 $crimeLocation');
    // Allow optional movement to crime scene
  }
  
  /// Add extra clue to specified location
  /// 向指定地点添加额外线索
  void _addExtraClueToLocation(String locationName) {
    var game = BlizzardManor();
    var location = game._locations[locationName];
    
    if (location != null) {
      // Generate a random extra clue
      var extraClues = ['痕迹：挣扎', '痕迹：血迹', '遗留物：纤维'];
      var random = Random();
      var extraClue = extraClues[random.nextInt(extraClues.length)];
      
      location.extraClues.add(extraClue);
      Log.instance.record('Extra clue added to $locationName: $extraClue');
    }
  }
  
  /// Get killer status for director
  /// 获取凶手状态给导演
  Map<String, dynamic> getKillerStatus() {
    return {
      'motive': motive,
      'availableMethods': availableMethods,
      'availableClues': availableClues,
      'methodUsage': methodUsageCount,
      'hasKilledSuccessfully': hasKilledSuccessfully,
      'currentPlanSubmitted': currentPlan != null,
    };
  }
}

/// Represents a kill plan submitted by the killer
/// 凶手提交的杀人计划
class KillPlan {
  final String method;
  final String targetType; // 'player' or 'location'
  final String targetValue; // player name or location name
  final String clue;
  final String? trickMethod; // For fool deception
  final String? trickClue; // For fool deception
  
  KillPlan({
    required this.method,
    required this.targetType,
    required this.targetValue,
    required this.clue,
    this.trickMethod,
    this.trickClue,
  });
  
  @override
  String toString() {
    return 'KillPlan(method: $method, target: $targetType->$targetValue, clue: $clue)';
  }
}