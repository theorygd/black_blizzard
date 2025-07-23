part of blackblizzard;

// Occupation abstract class (base for all occupations)
abstract class Occupation {
  String get englishName;
  String get chineseName;
  List<Type> get mixins; // e.g., [Astute]
  void onDeath(Player player, Location location, [Map<String, dynamic>? context]) {}
  void useSkill(Player player, String skillName, [Map<String, dynamic>? params]) {}
}

// DoctorF = 医生女
class DoctorF extends Occupation with Astute {
  @override
  final String englishName = 'DoctorF';
  @override
  final String chineseName = '医生女';
  @override
  final List<Type> mixins = [Astute];

  @override
  void onDeath(Player player, Location location, [Map<String, dynamic>? context]) {
    final Location? loc1 = context?['location1'];
    final Location? loc2 = context?['location2'];
    if (loc1 != null) loc1.storeClue(Smells(isExtra: true));
    if (loc2 != null) loc2.storeClue(Smells(isExtra: true));
    Log().write('${player.name} (DoctorF) death triggered extra smell clues.');
  }
}
