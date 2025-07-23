// Location Base System - 地点基础系统
// Part of the main Black Blizzard TRPG simulation program
part of black_blizzard;

/// Location type enumeration
enum LocationType {
  lobby,      // 大厅
  bedroom,    // 卧室
  basement,   // 地下室
  kitchen,    // 厨房
  garden,     // 花园
  bathroom,   // 卫生间
  balcony,    // 阳台
}

/// Location effect enumeration
enum LocationEffect {
  secretRoom,     // 密室
  complexTerrain, // 复杂地形
  cooking,        // 料理
  closedSpace,    // 封闭空间
  flowing,        // 流水
  scenery,        // 观景
}

/// Crime information structure
class CrimeInformation {
  final String victim;
  final String location;
  final String causeOfDeath;
  final String clue;
  final DateTime timestamp;
  
  const CrimeInformation({
    required this.victim,
    required this.location,
    required this.causeOfDeath,
    required this.clue,
    required this.timestamp,
  });
  
  /// Check if this is complete crime information
  bool get isComplete => 
    victim.isNotEmpty && 
    location.isNotEmpty && 
    causeOfDeath.isNotEmpty && 
    clue.isNotEmpty;
  
  @override
  String toString() => '死者: $victim, 地点: $location, 死因: $causeOfDeath, 线索: $clue';
}

/// Additional clue structure
class AdditionalClue {
  final String type; // 痕迹 or 遗留物
  final String description;
  final String source; // Where this clue came from
  final DateTime timestamp;
  
  const AdditionalClue({
    required this.type,
    required this.description,
    required this.source,
    required this.timestamp,
  });
  
  @override
  String toString() => '$type: $description';
}

/// Base location abstract class
abstract class Location {
  final String id;
  final String name;
  final LocationType type;
  final int maxCapacity;
  final bool isDefaultLocation;
  
  // Current state
  final Set<String> _currentOccupants = <String>{};
  final List<CrimeInformation> _crimeInformation = [];
  final List<AdditionalClue> _additionalClues = [];
  final Set<LocationEffect> _activeEffects = <LocationEffect>{};
  
  Location({
    required this.id,
    required this.name,
    required this.type,
    required this.maxCapacity,
    this.isDefaultLocation = false,
  });
  
  // Occupancy management
  int get currentOccupancy => _currentOccupants.length;
  bool get isFull => currentOccupancy >= maxCapacity;
  bool get isEmpty => _currentOccupants.isEmpty;
  Set<String> get occupants => Set.unmodifiable(_currentOccupants);
  
  /// Add player to location
  bool addPlayer(String playerId) {
    if (isFull) return false;
    final added = _currentOccupants.add(playerId);
    if (added) {
      Log.instance.record('Player $playerId entered $name');
      _onPlayerEntered(playerId);
    }
    return added;
  }
  
  /// Remove player from location
  bool removePlayer(String playerId) {
    final removed = _currentOccupants.remove(playerId);
    if (removed) {
      Log.instance.record('Player $playerId left $name');
      _onPlayerLeft(playerId);
    }
    return removed;
  }
  
  /// Check if player can enter this location
  bool canPlayerEnter(Player player) {
    if (isFull) return false;
    return _checkSpecialEnterConditions(player);
  }
  
  /// Virtual method for special enter conditions
  bool _checkSpecialEnterConditions(Player player) => true;
  
  /// Virtual method called when player enters
  void _onPlayerEntered(String playerId) {
    // Override in specific location types
  }
  
  /// Virtual method called when player leaves
  void _onPlayerLeft(String playerId) {
    // Override in specific location types
  }
  
  // Crime information management
  List<CrimeInformation> getCrimeInformation() => List.unmodifiable(_crimeInformation);
  
  void addCrimeInformation(CrimeInformation info) {
    _crimeInformation.add(info);
    Log.instance.record('Crime information added to $name: ${info.victim}');
  }
  
  void clearCrimeInformation() {
    if (_crimeInformation.isNotEmpty) {
      Log.instance.record('Crime information cleared from $name');
      _crimeInformation.clear();
    }
  }
  
  // Additional clues management
  List<AdditionalClue> getAdditionalClues() => List.unmodifiable(_additionalClues);
  
  void addAdditionalClue(AdditionalClue clue) {
    _additionalClues.add(clue);
    Log.instance.record('Additional clue added to $name: ${clue.description}');
  }
  
  void clearAdditionalClues() {
    if (_additionalClues.isNotEmpty) {
      Log.instance.record('Additional clues cleared from $name');
      _additionalClues.clear();
    }
  }
  
  // Location effects management
  bool hasEffect(String effectName) {
    return _activeEffects.any((effect) => effect.toString().contains(effectName));
  }
  
  void addEffect(LocationEffect effect) {
    if (_activeEffects.add(effect)) {
      Log.instance.record('Effect ${effect.name} added to $name');
    }
  }
  
  void removeEffect(LocationEffect effect) {
    if (_activeEffects.remove(effect)) {
      Log.instance.record('Effect ${effect.name} removed from $name');
    }
  }
  
  Set<LocationEffect> get activeEffects => Set.unmodifiable(_activeEffects);
  
  // Special properties
  bool get hasRestrictions => _activeEffects.isNotEmpty || _hasSpecialRestrictions();
  bool _hasSpecialRestrictions() => false; // Override in specific locations
  
  /// Handle murder at this location
  virtual MurderResult handleMurder(MurderAction murder) {
    // Base implementation - override in specific locations
    return MurderResult.success;
  }
  
  /// Handle overnight stay effects
  virtual void handleOvernightStay(Player player) {
    // Override in specific locations for special overnight effects
  }
  
  /// Handle dawn effects
  virtual void handleDawnEffects(GameState gameState) {
    // Override in specific locations for dawn-specific effects
  }
  
  /// Get location description for players
  String getDescription() {
    final buffer = StringBuffer();
    buffer.writeln('地点: $name');
    buffer.writeln('当前人数: $currentOccupancy/$maxCapacity');
    
    if (_activeEffects.isNotEmpty) {
      buffer.writeln('特殊效果: ${_activeEffects.map((e) => e.name).join(', ')}');
    }
    
    return buffer.toString();
  }
  
  @override
  String toString() => '$name ($currentOccupancy/$maxCapacity)';
}

/// Location factory for creating specific location instances
class LocationFactory {
  static Location createLocation(LocationType type, int playerCount) {
    switch (type) {
      case LocationType.lobby:
        return LobbyLocation();
      case LocationType.bedroom:
        return BedroomLocation();
      case LocationType.basement:
        return BasementLocation();
      case LocationType.kitchen:
        return KitchenLocation();
      case LocationType.garden:
        return GardenLocation();
      case LocationType.bathroom:
        return BathroomLocation(playerCount);
      case LocationType.balcony:
        return BalconyLocation(playerCount);
    }
  }
  
  /// Create all locations based on player count
  static Map<String, Location> createAllLocations(int playerCount) {
    final locations = <String, Location>{};
    
    // Basic locations (always present)
    locations['lobby'] = createLocation(LocationType.lobby, playerCount);
    locations['bedroom'] = createLocation(LocationType.bedroom, playerCount);
    locations['basement'] = createLocation(LocationType.basement, playerCount);
    locations['kitchen'] = createLocation(LocationType.kitchen, playerCount);
    locations['garden'] = createLocation(LocationType.garden, playerCount);
    
    // Conditional locations based on player count
    if (playerCount >= 7) {
      locations['bathroom'] = createLocation(LocationType.bathroom, playerCount);
    }
    
    if (playerCount >= 8) {
      locations['balcony'] = createLocation(LocationType.balcony, playerCount);
    }
    
    Log.instance.record('Created ${locations.length} locations for $playerCount players');
    return locations;
  }
}

/// Murder result enumeration for location-specific murder handling
enum MurderResult {
  success,
  failed,
  blocked,
  locationEmpty,
  specialEffect,
}

/// Location manager class for handling all location-related operations
class LocationManager {
  final Map<String, Location> _locations = {};
  late final int _playerCount;
  
  LocationManager(int playerCount) : _playerCount = playerCount {
    _initializeLocations();
  }
  
  void _initializeLocations() {
    _locations.addAll(LocationFactory.createAllLocations(_playerCount));
    Log.instance.record('LocationManager initialized with ${_locations.length} locations');
  }
  
  // Location access
  Location? getLocation(String locationId) => _locations[locationId];
  
  Location getLocationOrThrow(String locationId) {
    final location = _locations[locationId];
    if (location == null) {
      throw ArgumentError('Location not found: $locationId');
    }
    return location;
  }
  
  List<Location> getAllLocations() => _locations.values.toList();
  
  Location getDefaultLocation() {
    return _locations.values.firstWhere(
      (location) => location.isDefaultLocation,
      orElse: () => _locations['lobby']!, // Lobby is always the fallback default
    );
  }
  
  // Location state management
  bool isLocationAccessible(Location location) {
    // Check if location exists and is accessible
    return _locations.containsValue(location) && !_isLocationRestricted(location);
  }
  
  bool _isLocationRestricted(Location location) {
    // Check for special restrictions like bedroom 密室 effect
    if (location.id == 'bedroom' && location.hasEffect('密室')) {
      return true;
    }
    return false;
  }
  
  /// Move player between locations
  bool movePlayer(String playerId, String fromLocationId, String toLocationId) {
    final fromLocation = getLocation(fromLocationId);
    final toLocation = getLocation(toLocationId);
    
    if (fromLocation == null || toLocation == null) {
      Log.instance.record('Movement failed: invalid location(s)');
      return false;
    }
    
    // Remove from current location
    if (!fromLocation.removePlayer(playerId)) {
      Log.instance.record('Movement failed: player not in source location');
      return false;
    }
    
    // Add to target location
    if (!toLocation.addPlayer(playerId)) {
      // Failed to add - return player to original location
      fromLocation.addPlayer(playerId);
      Log.instance.record('Movement failed: target location full or restricted');
      return false;
    }
    
    Log.instance.record('Player $playerId moved from ${fromLocation.name} to ${toLocation.name}');
    return true;
  }
  
  /// Update balcony effect on garden occupancy calculation
  void updateBalconyEffect() {
    final balcony = getLocation('balcony');
    final garden = getLocation('garden');
    
    if (balcony != null && garden != null) {
      // Each player on balcony counts as +2 for garden occupancy checks
      final balconyOccupancy = balcony.currentOccupancy;
      Log.instance.record('Balcony effect: $balconyOccupancy players add ${balconyOccupancy * 2} to garden count');
    }
  }
  
  /// Handle dawn effects for all locations
  void handleDawnEffects(GameState gameState) {
    Log.instance.record('Processing dawn effects for all locations');
    
    for (final location in _locations.values) {
      location.handleDawnEffects(gameState);
    }
    
    // Clear all crime information and additional clues at end of day
    _clearEndOfDayInformation();
  }
  
  /// Clear all crime information and additional clues at end of day
  void _clearEndOfDayInformation() {
    for (final location in _locations.values) {
      location.clearCrimeInformation();
      location.clearAdditionalClues();
    }
    Log.instance.record('End of day: all location information cleared');
  }
  
  /// Get locations summary for game master
  String getLocationsSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== 地点状况总览 ===');
    
    for (final location in _locations.values) {
      buffer.writeln('${location.name}: ${location.currentOccupancy}/${location.maxCapacity}人');
      
      if (location.occupants.isNotEmpty) {
        buffer.writeln('  玩家: ${location.occupants.join(', ')}');
      }
      
      if (location.activeEffects.isNotEmpty) {
        buffer.writeln('  效果: ${location.activeEffects.map((e) => e.name).join(', ')}');
      }
      
      final crimeInfo = location.getCrimeInformation();
      if (crimeInfo.isNotEmpty) {
        buffer.writeln('  犯罪信息: ${crimeInfo.length}条');
      }
      
      final clues = location.getAdditionalClues();
      if (clues.isNotEmpty) {
        buffer.writeln('  额外线索: ${clues.length}条');
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Get available locations for player count
  List<String> getAvailableLocationIds() => _locations.keys.toList();
  
  /// Check if location combination is valid for game rules
  bool validateLocationSetup() {
    // Ensure all required locations exist
    final requiredLocations = ['lobby', 'bedroom', 'basement', 'kitchen', 'garden'];
    for (final required in requiredLocations) {
      if (!_locations.containsKey(required)) {
        Log.instance.record('Validation failed: missing required location $required');
        return false;
      }
    }
    
    // Check player count specific requirements
    if (_playerCount >= 7 && !_locations.containsKey('bathroom')) {
      Log.instance.record('Validation failed: bathroom required for 7+ players');
      return false;
    }
    
    if (_playerCount >= 8 && !_locations.containsKey('balcony')) {
      Log.instance.record('Validation failed: balcony required for 8+ players');
      return false;
    }
    
    Log.instance.record('Location setup validation passed');
    return true;
  }
}