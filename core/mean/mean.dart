part of blackblizzard;

// Mean abstract class (base for all murder means)

abstract class Mean {
  final String name;
  final String description;
  final String chineseName;
  final bool isPoison;

  Mean(this.name, this.description, this.chineseName, {this.isPoison = false});

  /// Whether this mean is available for the user in the current context
  bool isAvailable(Player user, [Map<String, dynamic>? context]);

  /// Execute the mean (e.g., perform a murder)
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params});
}

// Corpse clue (for murder result)
class CorpseClue extends Clue {
  final Player victim;
  final Mean mean;
  final Clue usedClue;
  CorpseClue(this.victim, this.mean, this.usedClue)
      : super('Corpse', 'Corpse clue', '尸体线索');
}
