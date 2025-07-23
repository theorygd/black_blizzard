part of blackblizzard;

// Occupation abstract class (base for all occupations)
// Occupation depends on all concrete occupation files
part 'doctor_f.dart';
part 'traveller_m.dart';
part 'guide_f.dart';
part 'soldier_m.dart';
part 'manager_m.dart';

abstract class Occupation {
  String get englishName;
  String get chineseName;
  List<Type> get mixins; // e.g., [Astute]
  void onDeath(Player player, Location location, [Map<String, dynamic>? context]) {}
  void useSkill(Player player, String skillName, [Map<String, dynamic>? params]) {}
}
