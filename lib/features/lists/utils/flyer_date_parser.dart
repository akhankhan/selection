/// Parses the end date from store flyer date-range strings such as
/// "May 21 - May 28, 2026" or "Jun 20 - Jun 26".
DateTime? parseFlyerExpiryDate(String dateRange) {
  final trimmed = dateRange.trim();
  if (trimmed.isEmpty) return null;

  const monthNames = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  final pattern = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2})(?:,?\s+(\d{4}))?',
    caseSensitive: false,
  );

  DateTime? latest;
  for (final match in pattern.allMatches(trimmed)) {
    final monthKey = match.group(1)!.substring(0, 3).toLowerCase();
    final month = monthNames[monthKey];
    if (month == null) continue;

    final day = int.tryParse(match.group(2)!);
    if (day == null) continue;

    final year = match.group(3) != null
        ? int.tryParse(match.group(3)!)
        : DateTime.now().year;
    if (year == null) continue;

    final candidate = DateTime(year, month, day, 23, 59, 59);
    if (latest == null || candidate.isAfter(latest)) {
      latest = candidate;
    }
  }

  return latest;
}

bool isFlyerExpired(DateTime? expiresAt, [DateTime? reference]) {
  if (expiresAt == null) return false;
  return expiresAt.isBefore(reference ?? DateTime.now());
}
