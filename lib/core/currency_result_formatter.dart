/// Maps a model class label (e.g. "1000Rs", "1000Rsback") to display-ready strings.
///
/// The trained model has 14 classes: 7 denominations × front/back.
/// Labels ending in "back" are the reverse side of the note.
/// The Urdu sentences mention the denomination only — not the side —
/// since denomination is what matters financially for a blind user.
class CurrencyResultFormatter {
  /// English label shown in the result card.
  /// Includes "(back)" suffix so the user knows which side was detected.
  static String toEnglishLabel(String classLabel) {
    final cleanLabel = classLabel.trim();
    final isBack = cleanLabel.endsWith('back') || cleanLabel.endsWith('Back');

    // Determine denomination value
    String denom;
    if (cleanLabel.contains('5000')) {
      denom = 'Rs 5,000';
    } else if (cleanLabel.contains('1000')) {
      denom = 'Rs 1,000';
    } else if (cleanLabel.contains('500')) {
      denom = 'Rs 500';
    } else if (cleanLabel.contains('100')) {
      denom = 'Rs 100';
    } else if (cleanLabel.contains('50')) {
      denom = 'Rs 50';
    } else if (cleanLabel.contains('20')) {
      denom = 'Rs 20';
    } else if (cleanLabel.contains('10')) {
      denom = 'Rs 10';
    } else {
      return cleanLabel; // Unknown label — return as-is
    }

    return isBack ? '$denom (back)' : denom;
  }

  /// Urdu sentence spoken aloud.
  /// These are fixed, pre-written strings — not AI-generated.
  /// Explicitly states whether the detected note is the front or back side
  /// to provide comprehensive tactile and spatial awareness for blind users.
  static String toUrduSentence(String classLabel) {
    final cleanLabel = classLabel.trim();
    final isBack = cleanLabel.endsWith('back') || cleanLabel.endsWith('Back');

    if (cleanLabel.contains('5000')) {
      return isBack
          ? 'یہ پانچ ہزار روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ پانچ ہزار روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('1000')) {
      return isBack
          ? 'یہ ایک ہزار روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ ایک ہزار روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('500')) {
      return isBack
          ? 'یہ پانچ سو روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ پانچ سو روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('100')) {
      return isBack
          ? 'یہ سو روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ سو روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('50')) {
      return isBack
          ? 'یہ پچاس روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ پچاس روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('20')) {
      return isBack
          ? 'یہ بیس روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ بیس روپے کے نوٹ کی اگلی طرف ہے';
    }
    if (cleanLabel.contains('10')) {
      return isBack
          ? 'یہ دس روپے کے نوٹ کی پچھلی طرف ہے'
          : 'یہ دس روپے کے نوٹ کی اگلی طرف ہے';
    }

    return 'نوٹ کی پہچان نہیں ہو سکی';
  }

  /// Urdu retry error sentence — used by the error-state UI and spoken automatically.
  static const String urduRetryMessage =
      'نوٹ صاف نظر نہیں آ رہا، دوبارہ کوشش کریں';
}
