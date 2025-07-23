// core/location/bedroom.dart
// Bedroom location implementation with locked room (密室) logic and timing-based hooks

part of blackblizzard;

class Bedroom extends Location {
  final String chineseName;
  bool isLockedRoom = false;
  bool lockedRoomTriggered = false; // Only trigger once per game
  bool extraClueOnMurderUsed = false; // Only trigger once per game

  Bedroom(LocationId id)
      : chineseName = '卧室', super(id, 'Bedroom', enabled: true, state: 'normal', capacity: 3);

  /// Check and activate locked room state at dawn
  /// Returns true if locked room is activated
  bool checkAndActivateLockedRoom({required int aliveCount, required int deadCount}) {
    if (!lockedRoomTriggered && aliveCount == 0 && deadCount == 1) {
      isLockedRoom = true;
      state = 'locked';
      lockedRoomTriggered = true;
      Log().write('Bedroom locked room state activated.');
      return true;
    }
    return false;
  }

  /// Deactivate locked room state (when any player enters)
  void deactivateLockedRoom() {
    isLockedRoom = false;
    state = 'normal';
    Log().write('Bedroom locked room state deactivated.');
  }

  /// BeforeEnterSkill: check if player can enter (locked room blocks entry)
  SkillResult onBeforeEnter({required Player player}) {
    if (isLockedRoom) {
      Log().write('Player ${player.id} failed to enter locked Bedroom.');
      return SkillResult(false, '【门打不开！】', null);
    }
    return SkillResult(true, '', null);
  }

  /// AfterEnterSkill: if locked room, deactivate on first entry
  SkillResult onAfterEnter({required Player player}) {
    if (isLockedRoom) {
      deactivateLockedRoom();
      return SkillResult(true, 'Locked room state deactivated.', null);
    }
    return SkillResult(true, '', null);
  }

  /// When a murder occurs in Bedroom, trigger extra clue (only once)
  /// Used for 密室 or 善战等特性
  bool triggerExtraClueOnMurder(Clue clue, Mean mean) {
    if (!extraClueOnMurderUsed) {
      extraClueOnMurderUsed = true;
      generateExtraClue(clue, mean);
      Log().write('Extra clue triggered for murder in Bedroom.');
      return true;
    }
    return false;
  }
}
