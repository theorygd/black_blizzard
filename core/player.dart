part of blackblizzard;

// Player abstract class and attribute mixins
// Attribute mixins: Astute(敏锐), Reasoning(推理), Mighty(善战)

part 'occupation/occupation.dart';

mixin Astute on Player {
  @override
  bool get hasAstute => true;
}

mixin Reasoning on Player {
  @override
  bool get hasReasoning => true;
}

mixin Mighty on Player {
  @override
  bool get hasMighty => true;
}

abstract class Player {
  final PlayerId id;
  final String name;
  String nickname;
  LocationId locationId;
  OccupationId occupationId; // Occupation (e.g., DoctorF, TravellerM)
  CharacterId characterId;   // Character (e.g., Murderer, Fool)

  Player(this.id, this.name, this.nickname, this.locationId, this.occupationId, this.characterId);

  void sendMessage(String message);
  void useSkill(String skillName, [Map<String, dynamic>? params]);
  void moveTo(LocationId targetLocation);
  void vote(PlayerId targetPlayer);
  void activateChannel();

  /// Attribute checks (default false, override by mixin)
  bool get hasAstute => false;      // 敏锐 Astute
  bool get hasReasoning => false;   // 推理 Reasoning
  bool get hasMighty => false;      // 善战 Mighty
  bool get isFool => false;

  void onCluePickup(Clue clue, [Map<String, dynamic>? context]) {}
  void onDeath(Location location, [Map<String, dynamic>? context]) {}
  void onSkillTrigger(String skillName, [Map<String, dynamic>? context]) {}
}
