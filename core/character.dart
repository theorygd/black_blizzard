// core/character.dart
// Character abstract class and its implementations: Murderer, PassiveFool

part of blackblizzard;

/// Motive for Murderer
enum MurdererMotive {
  pleasure, // 愉悦
  premeditation, // 预谋
  sacrifice, // 献祭
  dream // 迷梦
}

/// Abstract class for player character (identity)
abstract class Character {
  final CharacterId id;
  final String name;

  Character(this.id, this.name);

  /// Use a character-specific skill
  void useCharacterSkill(String skillName, [Map<String, dynamic>? params]);
}

/// Murderer implementation
class Murderer extends Character {
  MurdererMotive motive;
  List<Clue> availableClues;
  Set<Clue> usedClues = {};
  List<String> availableMethods; // e.g., ["stab", "blunt", "strangle"]
  Set<String> usedMethods = {};
  bool hasUsedQuickMove = false; // For "疾行"
  bool hasFailedCrime = false; // For imperfect crime
  List<String> knownFools = [];

  Murderer(
    CharacterId id,
    String name, {
    required this.motive,
    required this.availableMethods,
    required this.availableClues,
    this.knownFools = const [],
  }) : super(id, name);

  /// Consume a clue (can only use each clue once)
  void consumeClue(Clue clue) {
    if (usedClues.contains(clue)) throw Exception('Clue already used');
    usedClues.add(clue);
    availableClues.remove(clue);
    Log().write('Murderer consumed clue: ${clue.name}');
  }

  /// Get all available clues
  List<Clue> getAvailableClues() => List.unmodifiable(availableClues);

  /// Submit a murder plan (must be called every night)
  void submitMurderPlan({
    required String method,
    required String process, // "target" or "location"
    required String clue,
    String? trickMethod,
    String? trickClue,
  }) {
    // TODO: Validate and record the plan, check for rule compliance
    usedMethods.add(method);
    usedClues.add(clue);
    Log().write('Murderer submitted a plan: method=$method, process=$process, clue=$clue');
  }

  /// Activate quick move (疾行)
  void activateQuickMove() {
    if (hasUsedQuickMove) {
      throw Exception('Quick move can only be used once.');
    }
    hasUsedQuickMove = true;
    Log().write('Murderer used quick move.');
  }

  @override
  void useCharacterSkill(String skillName, [Map<String, dynamic>? params]) {
    // TODO: Implement skill logic based on skillName
    Log().write('Murderer used skill: $skillName');
  }
}

/// Passive Fool implementation (only has passive skill: Powerless)
class PassiveFool extends Character {
  bool isAware = false; // Fool never knows their identity
  PassiveFool(CharacterId id, String name) : super(id, name);

  /// Trigger the passive skill: Powerless
  void triggerPassiveSkill(String info) {
    // Powerless: Fool receives trick info instead of crime info
    Log().write('Fool (passive) triggered Powerless: received trick info: $info');
  }
}
