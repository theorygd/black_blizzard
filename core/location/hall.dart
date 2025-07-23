// core/location/hall.dart
// Hall location implementation

part of blackblizzard;

class Hall extends Location {
  final String chineseName;
  Hall(LocationId id)
      : chineseName = '大厅', super(id, 'Hall', enabled: true, state: 'normal', capacity: 99); // unlimited capacity
} 