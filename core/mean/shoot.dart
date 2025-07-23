part of blackblizzard;

// Shoot mean (gun murder)

class ShootMean extends Mean {
  final String chineseName;
  ShootMean() : chineseName = '枪杀', super('Shoot', 'A gun murder.');

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Gun murder is available if user has a gun
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for gun murder
    Log().write('${user.name} used Shoot on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
