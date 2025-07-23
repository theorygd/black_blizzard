// core/location/bathroom.dart
// Bathroom location implementation

part of blackblizzard;

class Bathroom extends Location {
  final String chineseName;
  Bathroom(LocationId id)
      : chineseName = '卫生间', super(id, 'Bathroom', enabled: true, state: 'normal', capacity: 2);
} 