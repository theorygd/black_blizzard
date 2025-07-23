part of blackblizzard;

// ManagerM = 管理员男
class ManagerM extends Occupation {
  @override
  final String englishName = 'ManagerM';
  @override
  final String chineseName = '管理员男';
  @override
  final List<Type> mixins = [];

  @override
  void useSkill(Player player, String skillName, [Map<String, dynamic>? params]) {
    if (skillName == 'HomeAdvantage') {
      final Location? loc = params?['location'];
      if (loc != null) {
        final clues = loc.clues.where((c) => c is LeftoutClue && c.isExtra).toList();
        for (final clue in clues) {
          player.onCluePickup(clue);
        }
        Log().write('${player.name} (ManagerM) picked up extra leftout clues: ${clues.map((c) => c.name).join(', ')}');
      }
    }
  }
}
