part of blackblizzard;

// Trap mean (trap murder)

class TrapMean extends Mean {
  final String chineseName;
  TrapMean() : chineseName = '陷阱', super('Trap', 'A trap murder.');

  @override
  bool isAvailable(Player user, [Map<String, dynamic>? context]) {
    // Trap murder is available if user can set a trap
    return true; // TODO: check user inventory or context
  }

  @override
  void execute({required Player user, Player? targetPlayer, Location? location, Map<String, dynamic>? params}) {
    // TODO: Implement the logic for trap murder
    Log().write('${user.name} used Trap on ${targetPlayer?.name ?? 'unknown'} at ${location?.name ?? 'unknown'}');
  }
}
