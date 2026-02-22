class DateFormatter {
  static String relative(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
      return full(isoDate);
    } catch (_) {
      return isoDate;
    }
  }

  static String full(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const months = [
        'jan.',
        'fév.',
        'mar.',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sep.',
        'oct.',
        'nov.',
        'déc.',
      ];
      final m = months[date.month - 1];
      final h = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '${date.day} $m ${date.year} à ${h}h$min';
    } catch (_) {
      return isoDate;
    }
  }
}
