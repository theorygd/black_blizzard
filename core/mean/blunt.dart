part of blackblizzard;

// Blunt mean (blunt force murder)

class BluntMean extends Mean {
  final String chineseName;
  BluntMean() : chineseName = '钝击', super('Blunt', 'A basic blunt force murder.');

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Blunt murder is always available if user has a blunt weapon
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for blunt force murder
    Log().write('${user.name} used Blunt on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
