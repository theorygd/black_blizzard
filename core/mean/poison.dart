part of blackblizzard;

// Poison mean (poison murder)

class PoisonMean extends Mean {
  final String chineseName;
  PoisonMean() : chineseName = '毒杀', super('Poison', 'A poison murder.', '毒杀', isPoison: true);

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Poison murder is available if user has poison
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for poison murder
    Log().write('${user.name} used Poison on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
