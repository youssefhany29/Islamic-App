enum QuranHideMode {
  visible,
  partial,
  full,
}

extension QuranHideModeX on QuranHideMode {
  bool get isVisible => this == QuranHideMode.visible;

  bool get isPartial => this == QuranHideMode.partial;

  bool get isFull => this == QuranHideMode.full;

  bool get shouldHideAnyText => this != QuranHideMode.visible;

  String get label {
    switch (this) {
      case QuranHideMode.visible:
        return 'إظهار الآيات';
      case QuranHideMode.partial:
        return 'إخفاء جزئي';
      case QuranHideMode.full:
        return 'إخفاء الآيات';
    }
  }

  String get storageValue {
    switch (this) {
      case QuranHideMode.visible:
        return 'visible';
      case QuranHideMode.partial:
        return 'partial';
      case QuranHideMode.full:
        return 'full';
    }
  }

  static QuranHideMode fromStorageValue(String? value) {
    switch (value) {
      case 'partial':
        return QuranHideMode.partial;
      case 'full':
        return QuranHideMode.full;
      case 'visible':
      default:
        return QuranHideMode.visible;
    }
  }

  QuranHideMode toggleFullHide() {
    if (this == QuranHideMode.full) {
      return QuranHideMode.visible;
    }

    return QuranHideMode.full;
  }

  QuranHideMode next() {
    switch (this) {
      case QuranHideMode.visible:
        return QuranHideMode.partial;
      case QuranHideMode.partial:
        return QuranHideMode.full;
      case QuranHideMode.full:
        return QuranHideMode.visible;
    }
  }
}