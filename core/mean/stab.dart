part of blackblizzard;

// Stab mean (knife murder)

class StabMean extends Mean {
  final String chineseName;
  StabMean() : chineseName = '刀杀', super('Stab', 'A basic knife murder.');

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Knife murder is always available if user has a knife
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for knife murder
    Log().write('${user.name} used Stab on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
