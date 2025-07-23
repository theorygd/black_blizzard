part of blackblizzard;

// Strangle mean (strangulation murder)

class StrangleMean extends Mean {
  final String chineseName;
  StrangleMean() : chineseName = '绞杀', super('Strangle', 'A basic strangulation murder.');

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Strangulation is available if user has a rope or similar
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for strangulation
    Log().write('${user.name} used Strangle on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
