// core/location/garden.dart
// Garden location implementation with complex terrain logic and timing-based hooks

part of blackblizzard;

class Garden extends Location {
  final String chineseName;
  bool isComplexTerrain = false;
  bool dirtTraceAdded = false;
  bool infoDistributedThisDay = false;

  Garden(LocationId id)
      : chineseName = '花园', super(id, 'Garden', enabled: true, state: 'normal', capacity: 4);

  /// Activate complex terrain state
  void activateComplexTerrain() {
    isComplexTerrain = true;
    state = 'complex';
    Log().write('Garden complex terrain activated.');
  }

  /// Deactivate complex terrain state
  void deactivateComplexTerrain() {
    isComplexTerrain = false;
    state = 'normal';
    Log().write('Garden complex terrain deactivated.');
  }

  /// Add dirt trace clue (only once per night, not extra clue, never visible)
  void generateDirtTrace() {
    if (!dirtTraceAdded) {
      clues.add('<Trace: Dirt>'); // 这里仍用字符串，因不可被发现
      dirtTraceAdded = true;
      Log().write('Dirt trace clue added to Garden.');
    }
  }

  /// Reset dirt trace flag at dawn
  void resetDirtTrace() {
    dirtTraceAdded = false;
  }

  /// AfterEnterSkill: distribute crime info if player count reaches 4 (only once per day)
  SkillResult onAfterEnter({required Player player}) {
    if (this.players.length == 4 && !infoDistributedThisDay) {
      infoDistributedThisDay = true;
      final cluesGiven = pickupClues();
      Log().write('Garden crime info distributed to players.');
      return SkillResult(true, 'Crime info distributed: $cluesGiven', {'clues': cluesGiven});
    }
    return SkillResult(true, '', null);
  }

  /// Reset info distribution flag at dawn
  void resetInfoDistribution() {
    infoDistributedThisDay = false;
  }

  List<String> pickupClues() {
    final visibleClues = clues.where((c) => c != '<Trace: Dirt>').toList();
    clues.removeWhere((c) => c != '<Trace: Dirt>');
    return visibleClues;
  }
}
