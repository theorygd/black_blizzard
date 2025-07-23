part of blackblizzard;

// GuideF = 导游女
class GuideF extends Occupation with Astute {
  @override
  final String englishName = 'GuideF';
  @override
  final String chineseName = '导游女';
  @override
  final List<Type> mixins = [Astute];

  @override
  void useSkill(Player player, String skillName, [Map<String, dynamic>? params]) {
    if (skillName == 'PerfectMemory') {
      final Location? loc = params?['location'];
      if (loc != null) {
        final clues = loc.clues.where((c) => c is TraceClue && c.isExtra).toList();
        Log().write('${player.name} (GuideF) confirmed extra trace clues: ${clues.map((c) => c.name).join(', ')}');
      }
    }
  }
}
