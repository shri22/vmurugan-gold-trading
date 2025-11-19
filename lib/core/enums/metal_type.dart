enum MetalType { gold, silver }

extension MetalTypeExtension on MetalType {
  String get name {
    switch (this) {
      case MetalType.gold:
        return 'gold';
      case MetalType.silver:
        return 'silver';
    }
  }

  String get displayName {
    switch (this) {
      case MetalType.gold:
        return 'Gold';
      case MetalType.silver:
        return 'Silver';
    }
  }
}
