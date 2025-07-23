// core/location/kitchen.dart
// Kitchen location implementation

part of blackblizzard;

class Kitchen extends Location {
  final String chineseName;
  Kitchen(LocationId id)
      : chineseName = '厨房', super(id, 'Kitchen', enabled: true, state: 'normal', capacity: 2);
} 