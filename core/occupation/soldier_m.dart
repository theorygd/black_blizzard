part of blackblizzard;

// SoldierM = 军人男
class SoldierM extends Occupation with Mighty {
  @override
  final String englishName = 'SoldierM';
  @override
  final String chineseName = '军人男';
  @override
  final List<Type> mixins = [Mighty];

  @override
  void onDeath(Player player, Location location, [Map<String, dynamic>? context]) {
    final Mean? mean = context?['mean'];
    final Clue? extraClue = context?['extraClue'];
    if (mean != null && extraClue != null) {
      location.generateExtraClue(extraClue, mean);
      Log().write('${player.name} (SoldierM) death triggered extra clue: ${extraClue.name}');
    }
  }
} 