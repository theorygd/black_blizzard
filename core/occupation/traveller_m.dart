part of blackblizzard;

// TravellerM = 驴友男
class TravellerM extends Occupation with Astute, Mighty {
  @override
  final String englishName = 'TravellerM';
  @override
  final String chineseName = '驴友男';
  @override
  final List<Type> mixins = [Astute, Mighty];

  @override
  void useSkill(Player player, String skillName, [Map<String, dynamic>? params]) {
    if (skillName == 'CarefulMind') {
      final Location? loc = params?['location'];
      if (loc != null) {
        final clues = loc.pickupClues(picker: player);
        Log().write('${player.name} (TravellerM) picked up extra clues: ${clues.map((c) => c.name).join(', ')}');
      }
    }
  }
}
