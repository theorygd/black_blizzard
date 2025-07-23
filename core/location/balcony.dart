// core/location/balcony.dart
// Balcony location implementation

part of blackblizzard;

class Balcony extends Location {
  final String chineseName;
  Balcony(LocationId id)
      : chineseName = '阳台', super(id, 'Balcony', enabled: true, state: 'normal', capacity: 1);
} 