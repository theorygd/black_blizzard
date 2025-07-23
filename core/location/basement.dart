// core/location/basement.dart
// Basement location implementation

part of blackblizzard;

class Basement extends Location {
  final String chineseName;
  Basement(LocationId id)
      : chineseName = '地下室', super(id, 'Basement', enabled: true, state: 'normal', capacity: 1);
} 