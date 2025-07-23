// core/skill.dart
// Skill abstract class and its subtypes: ActionSkill (active), PassiveSkill (passive), and related enums and result class

part of blackblizzard;

/// Skill type: action, passive, or mixed
enum SkillType { action, passive, mixed }

/// Skill target type: none, player, location, info, or custom
enum SkillTargetType { none, player, location, info, custom }

/// Skill trigger type for passive skills
enum SkillTriggerType {
  onMove,
  onDeath,
  onInfoGain,
  onNightStart,
  onDayStart,
  onGameStart,
  custom
}

/// Skill trigger timing for event-driven abilities
enum SkillTriggerTiming {
  BeforeEnter,   // Before entering a location
  AfterEnter,    // After entering a location
  BeforeLeave,   // Before leaving a location
  AfterLeave,    // After leaving a location
  OnNightStart,
  OnNightEnd,
  OnDayStart,
  OnDayEnd,
  OnDeath,
  OnPickupClue,
  OnAction,      // Active skill
  Custom
}

/// Result of skill execution or trigger
class SkillResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? changes;
  SkillResult(this.success, this.message, [this.changes]);
}

/// Abstract base class for all skills
abstract class Skill {
  final String name;
  final String description;
  final SkillType type;

  Skill(this.name, this.description, this.type);

  /// Whether the skill is available for the user in the current context
  bool isAvailable(Player user, [Map<String, dynamic>? context]);
}

/// Active skill (Action)
abstract class ActionSkill extends Skill {
  final SkillTargetType targetType;
  final int cooldown; // -1 means unlimited, 0 means once per game, >0 means cooldown in turns

  ActionSkill(String name, String description, this.targetType, {this.cooldown = -1})
      : super(name, description, SkillType.action);

  /// Execute the action skill
  SkillResult execute({
    required Player user,
    Player? targetPlayer,
    LocationId? targetLocation,
    Map<String, dynamic>? params,
  });
}

/// Passive skill
abstract class PassiveSkill extends Skill {
  final SkillTriggerType triggerType;
  final bool unique; // true if can only be triggered once per game

  PassiveSkill(String name, String description, this.triggerType, {this.unique = false})
      : super(name, description, SkillType.passive);

  /// Trigger the passive skill (usually by an event)
  SkillResult onTrigger({
    required Player owner,
    Map<String, dynamic>? eventData,
  });
}

// Abstract skill for before entering a location
abstract class BeforeEnterSkill extends Skill {
  BeforeEnterSkill(String name, String description)
      : super(name, description, SkillType.passive);
  SkillResult onBeforeEnter({required Player player, required Location location});
}

// Abstract skill for after entering a location
abstract class AfterEnterSkill extends Skill {
  AfterEnterSkill(String name, String description)
      : super(name, description, SkillType.passive);
  SkillResult onAfterEnter({required Player player, required Location location});
}

// You can add more timing-based skill subclasses as needed (BeforeLeaveSkill, OnDeathSkill, etc.)
