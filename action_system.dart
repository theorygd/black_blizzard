// Player Action System - 玩家行动系统
// Part of the main Black Blizzard TRPG simulation program
part of black_blizzard;

/// Player action result enumeration
enum ActionResult {
  success,
  failed,
  blocked,
  invalidTarget,
  insufficientResource,
  cooldownActive,
  locationFull
}

/// Base action class - all player actions inherit from this
abstract class PlayerAction {
  final String actionId;
  final Player performer;
  final GameTime gameTime;
  final String description;
  
  PlayerAction({
    required this.actionId,
    required this.performer,
    required this.gameTime,
    required this.description,
  });
  
  /// Execute the action and return result
  Future<ActionResult> execute(GameState gameState);
  
  /// Check if action can be performed
  bool canExecute(GameState gameState);
  
  /// Get action priority for ordering
  int get priority => 0;
  
  /// Log the action execution
  void logExecution(ActionResult result) {
    Log.instance.record(
      'Action executed: ${performer.name} -> $description. Result: $result'
    );
  }
}

/// Movement action class
class MovementAction extends PlayerAction {
  final Location targetLocation;
  final bool isNormalMovement; // true for normal movement, false for special movement
  
  MovementAction({
    required Player performer,
    required this.targetLocation,
    required GameTime gameTime,
    this.isNormalMovement = true,
  }) : super(
    actionId: 'move_${performer.id}_${targetLocation.id}',
    performer: performer,
    gameTime: gameTime,
    description: '移动到${targetLocation.name}',
  );
  
  @override
  bool canExecute(GameState gameState) {
    // Check if player has movement remaining
    if (isNormalMovement && performer.movementRemaining <= 0) {
      return false;
    }
    
    // Check if target location exists and is accessible
    if (!gameState.locationManager.isLocationAccessible(targetLocation)) {
      return false;
    }
    
    // Check special location restrictions
    if (targetLocation.hasRestrictions && 
        !targetLocation.canPlayerEnter(performer)) {
      return false;
    }
    
    return true;
  }
  
  @override
  Future<ActionResult> execute(GameState gameState) async {
    if (!canExecute(gameState)) {
      logExecution(ActionResult.failed);
      return ActionResult.failed;
    }
    
    final currentLocation = performer.currentLocation;
    
    // Check if target location is full
    if (targetLocation.currentOccupancy >= targetLocation.maxCapacity) {
      // Move player to default location
      final defaultLocation = gameState.locationManager.getDefaultLocation();
      performer.setLocation(defaultLocation);
      
      // Consume movement if normal movement
      if (isNormalMovement) {
        performer.consumeMovement();
      }
      
      // Don't notify player of failure (as per rules)
      Log.instance.record(
        'Movement failed - location full. ${performer.name} moved to ${defaultLocation.name}'
      );
      
      logExecution(ActionResult.locationFull);
      return ActionResult.locationFull;
    }
    
    // Execute movement
    performer.setLocation(targetLocation);
    
    // Consume movement if normal movement
    if (isNormalMovement) {
      performer.consumeMovement();
    }
    
    // Check for crime information at new location
    await _handleCrimeInformationDiscovery(gameState);
    
    // Handle special location effects
    await _handleLocationSpecialEffects(gameState);
    
    // Notify relevant streams
    gameState.notifyMovement(performer, currentLocation, targetLocation);
    
    logExecution(ActionResult.success);
    return ActionResult.success;
  }
  
  /// Handle discovery of crime information when entering a location
  Future<void> _handleCrimeInformationDiscovery(GameState gameState) async {
    final crimeInfo = targetLocation.getCrimeInformation();
    if (crimeInfo.isNotEmpty) {
      // Player discovers crime information
      performer.discoverCrimeInformation(crimeInfo);
      
      // Remove crime information from location
      targetLocation.clearCrimeInformation();
      
      Log.instance.record(
        '${performer.name} discovered crime information at ${targetLocation.name}'
      );
    }
    
    // Handle additional clues if player has [敏锐] ability
    if (performer.hasAbility('敏锐')) {
      final additionalClues = targetLocation.getAdditionalClues();
      if (additionalClues.isNotEmpty) {
        performer.discoverAdditionalClues(additionalClues);
        targetLocation.clearAdditionalClues();
        
        Log.instance.record(
          '${performer.name} discovered additional clues at ${targetLocation.name} (敏锐)'
        );
      }
    }
  }
  
  /// Handle special effects when entering certain locations
  Future<void> _handleLocationSpecialEffects(GameState gameState) async {
    // Special handling for bedroom密室 effect
    if (targetLocation.id == 'bedroom' && targetLocation.hasEffect('密室')) {
      targetLocation.removeEffect('密室');
      Log.instance.record('密室 effect removed from bedroom');
    }
    
    // Handle balcony->bedroom special movement
    if (performer.previousLocation?.id == 'balcony' && 
        targetLocation.id == 'bedroom') {
      // This movement doesn't consume movement points (as per rules)
      performer.restoreMovement();
      Log.instance.record(
        '${performer.name} moved from balcony to bedroom without consuming movement'
      );
    }
  }
  
  @override
  int get priority => 10; // Movement has medium priority
}

/// Skill usage action class
class SkillAction extends PlayerAction {
  final Skill skill;
  final List<Player> targets;
  final Map<String, dynamic> parameters;
  
  SkillAction({
    required Player performer,
    required this.skill,
    required GameTime gameTime,
    this.targets = const [],
    this.parameters = const {},
  }) : super(
    actionId: 'skill_${performer.id}_${skill.id}',
    performer: performer,
    gameTime: gameTime,
    description: '使用技能: ${skill.name}',
  );
  
  @override
  bool canExecute(GameState gameState) {
    // Check if player has the skill
    if (!performer.hasSkill(skill.id)) {
      return false;
    }
    
    // Check skill cooldown and usage restrictions
    if (!skill.canUse(gameTime)) {
      return false;
    }
    
    // Check if skill can be used in current phase
    if (gameTime.phase == GamePhase.night && !skill.canUseAtNight) {
      return false;
    }
    if (gameTime.phase == GamePhase.day && !skill.canUseAtDay) {
      return false;
    }
    
    // Validate targets
    if (!_validateTargets(gameState)) {
      return false;
    }
    
    return true;
  }
  
  @override
  Future<ActionResult> execute(GameState gameState) async {
    if (!canExecute(gameState)) {
      logExecution(ActionResult.failed);
      return ActionResult.failed;
    }
    
    // Execute skill effect
    final result = await skill.execute(
      performer: performer,
      targets: targets,
      gameState: gameState,
      parameters: parameters,
    );
    
    // Mark skill as used
    skill.markUsed(gameTime);
    
    // Notify relevant streams
    gameState.notifySkillUsage(performer, skill, targets, result);
    
    logExecution(result);
    return result;
  }
  
  /// Validate skill targets
  bool _validateTargets(GameState gameState) {
    if (skill.requiresTarget && targets.isEmpty) {
      return false;
    }
    
    // Check target validity based on skill requirements
    for (final target in targets) {
      if (!skill.isValidTarget(performer, target, gameState)) {
        return false;
      }
    }
    
    return true;
  }
  
  @override
  int get priority => skill.priority;
}

/// Investigation action class (for day phase reasoning)
class InvestigationAction extends PlayerAction {
  final Location investigationSite;
  
  InvestigationAction({
    required Player performer,
    required this.investigationSite,
    required GameTime gameTime,
  }) : super(
    actionId: 'investigate_${performer.id}_${investigationSite.id}',
    performer: performer,
    gameTime: gameTime,
    description: '在${investigationSite.name}进行推理',
  );
  
  @override
  bool canExecute(GameState gameState) {
    // Can only investigate during day phase
    if (gameTime.phase != GamePhase.day) {
      return false;
    }
    
    // Player must have [推理] ability
    if (!performer.hasAbility('推理')) {
      return false;
    }
    
    // Player must be at the investigation site
    if (performer.currentLocation != investigationSite) {
      return false;
    }
    
    return true;
  }
  
  @override
  Future<ActionResult> execute(GameState gameState) async {
    if (!canExecute(gameState)) {
      logExecution(ActionResult.failed);
      return ActionResult.failed;
    }
    
    // Get additional clues from current location
    final additionalClues = investigationSite.getAdditionalClues();
    if (additionalClues.isNotEmpty) {
      performer.discoverAdditionalClues(additionalClues);
      investigationSite.clearAdditionalClues();
      
      Log.instance.record(
        '${performer.name} used 推理 at ${investigationSite.name} and found clues'
      );
    }
    
    logExecution(ActionResult.success);
    return ActionResult.success;
  }
  
  @override
  int get priority => 5; // Investigation has lower priority
}

/// Action manager class - handles action queuing and execution
class ActionManager {
  final List<PlayerAction> _actionQueue = [];
  final List<PlayerAction> _executedActions = [];
  late final GameState _gameState;
  
  ActionManager(GameState gameState) : _gameState = gameState;
  
  /// Add action to queue
  void queueAction(PlayerAction action) {
    _actionQueue.add(action);
    Log.instance.record('Action queued: ${action.description} by ${action.performer.name}');
  }
  
  /// Execute all queued actions in proper order
  Future<void> executeQueuedActions() async {
    if (_actionQueue.isEmpty) return;
    
    // Sort actions by priority and night action order if applicable
    _actionQueue.sort((a, b) {
      if (_gameState.gameTime.phase == GamePhase.night) {
        return _compareNightActionOrder(a, b);
      } else {
        return b.priority.compareTo(a.priority);
      }
    });
    
    Log.instance.record('Executing ${_actionQueue.length} queued actions');
    
    // Execute actions in order
    for (final action in List.from(_actionQueue)) {
      // Check if performer is still alive
      if (!action.performer.isAlive) {
        Log.instance.record('Skipping action - performer ${action.performer.name} is eliminated');
        continue;
      }
      
      final result = await action.execute(_gameState);
      _executedActions.add(action);
      
      // Handle special cases based on action result
      await _handleActionResult(action, result);
    }
    
    _actionQueue.clear();
    Log.instance.record('All queued actions executed');
  }
  
  /// Compare actions for night action order
  int _compareNightActionOrder(PlayerAction a, PlayerAction b) {
    const nightOrder = [
      '灵媒', '学生', '男医生', '道具师', '女医生', 
      '女驴友', '导游', '管理员', '凶手', '侦探'
    ];
    
    final aIndex = nightOrder.indexOf(a.performer.characterTemplate.name);
    final bIndex = nightOrder.indexOf(b.performer.characterTemplate.name);
    
    if (aIndex == -1 && bIndex == -1) return 0;
    if (aIndex == -1) return 1;
    if (bIndex == -1) return -1;
    
    return aIndex.compareTo(bIndex);
  }
  
  /// Handle specific results from action execution
  Future<void> _handleActionResult(PlayerAction action, ActionResult result) async {
    switch (result) {
      case ActionResult.locationFull:
        // Notify streams about failed movement
        _gameState.notifyActionResult(action.performer, action, result);
        break;
      case ActionResult.success:
        // Handle successful actions
        if (action is MovementAction) {
          await _checkForSpecialEffects(action);
        }
        break;
      default:
        break;
    }
  }
  
  /// Check for special effects after successful movement
  Future<void> _checkForSpecialEffects(MovementAction movement) async {
    final location = movement.targetLocation;
    final player = movement.performer;
    
    // Check for location-specific effects
    switch (location.id) {
      case 'garden':
        await _handleGardenEffects(player, location);
        break;
      case 'kitchen':
        await _handleKitchenEffects(player, location);
        break;
      case 'basement':
        await _handleBasementEffects(player, location);
        break;
      case 'bathroom':
        await _handleBathroomEffects(player, location);
        break;
      case 'balcony':
        await _handleBalconyEffects(player, location);
        break;
    }
  }
  
  /// Handle garden-specific effects
  Future<void> _handleGardenEffects(Player player, Location garden) async {
    // Garden complex terrain effect - check if 4 players present
    if (garden.currentOccupancy >= 4) {
      final crimeInfo = garden.getCrimeInformation();
      if (crimeInfo.isNotEmpty) {
        player.discoverCrimeInformation(crimeInfo);
        garden.clearCrimeInformation();
        
        Log.instance.record(
          '${player.name} discovered crime info in garden (4+ players present)'
        );
      }
    }
  }
  
  /// Handle kitchen-specific effects
  Future<void> _handleKitchenEffects(Player player, Location kitchen) async {
    // Kitchen effects are handled during murder actions
    Log.instance.record('${player.name} entered kitchen');
  }
  
  /// Handle basement-specific effects
  Future<void> _handleBasementEffects(Player player, Location basement) async {
    Log.instance.record('${player.name} entered basement (封闭空间 protection)');
  }
  
  /// Handle bathroom-specific effects
  Future<void> _handleBathroomEffects(Player player, Location bathroom) async {
    // Bathroom effects are handled during murder actions
    Log.instance.record('${player.name} entered bathroom');
  }
  
  /// Handle balcony-specific effects
  Future<void> _handleBalconyEffects(Player player, Location balcony) async {
    // Balcony affects garden occupancy calculation
    _gameState.locationManager.updateBalconyEffect();
    Log.instance.record('${player.name} entered balcony (观景 effect active)');
  }
  
  /// Get list of executed actions for this phase
  List<PlayerAction> getExecutedActions() => List.unmodifiable(_executedActions);
  
  /// Clear executed actions (called at phase end)
  void clearExecutedActions() {
    _executedActions.clear();
  }
  
  /// Cancel all queued actions (emergency use)
  void cancelAllActions() {
    Log.instance.record('All queued actions cancelled');
    _actionQueue.clear();
  }
  
  /// Get current queue size
  int get queueSize => _actionQueue.length;
}