// core/location.dart
// Location abstract class and its public interface

part of blackblizzard;

part 'mean/mean.dart';
part 'clue/clue.dart';

/// Abstract base class for all locations
abstract class Location {
  final LocationId id;
  final String name;
  bool enabled;
  String state; // e.g., "normal", "locked", "complex", etc.
  final int capacity;
  final List<PlayerId> players = [];
  final List<Clue> clues = [];

  Location(this.id, this.name, {this.enabled = true, this.state = "normal", required this.capacity});

  /// Add a player to the location
  bool addPlayer(PlayerId playerId) {
    if (isFull) return false;
    players.add(playerId);
    return true;
  }

  /// Remove a player from the location
  bool removePlayer(PlayerId playerId) {
    return players.remove(playerId);
  }

  /// Whether the location is full
  bool get isFull => players.length >= capacity;

  /// Store a clue in the location
  void storeClue(Clue clue) {
    clues.add(clue);
  }

  /// Pick up clues (敏锐可拾取额外线索，愚者获得诡计信息)
  List<Clue> pickupClues({Player? picker}) {
    if (picker == null) return [];
    bool includeExtra = picker.hasSharpSense;
    final picked = clues.where((c) => includeExtra || !c.isExtra).toList();
    for (final clue in picked) {
      if (picker.isFool) {
        // TODO: Replace with trick info for fool
        Log().write('${picker.name} (Fool) picked up trick info for clue: ${clue.name}');
      } else {
        clue.onPickup(picker);
      }
    }
    clues.removeWhere((c) => picked.contains(c));
    return picked;
  }

  /// Clear all clues (e.g., at dusk)
  void clearClues() {
    clues.clear();
  }

  /// Generate a corpse clue (for murder result)
  void generateCorpseClue(Player victim, Mean mean, Clue usedClue) {
    storeClue(CorpseClue(victim, mean, usedClue));
  }

  /// Generate an extra clue (for imperfect crime, not for poison)
  void generateExtraClue(Clue clue, Mean mean) {
    if (!mean.isPoison) {
      storeClue(clue);
      Log().write('Extra clue generated: ${clue.name}');
    }
  }
}

// Export all concrete locations for easy import
part 'location/hall.dart';
part 'location/bedroom.dart';
part 'location/garden.dart';
part 'location/kitchen.dart';
part 'location/basement.dart';
part 'location/bathroom.dart';
part 'location/balcony.dart';
