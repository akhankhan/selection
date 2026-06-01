/// Helpers for rewriting Cloudinary image URLs with on-the-fly
/// transformations so we never download the full-resolution original.
///
/// Cloudinary upload URLs have the shape:
/// `https://res.cloudinary.com/{cloud}/image/upload/{publicId}.{ext}`
///
/// Transformations slot in right after `/upload/`, e.g.:
/// `https://res.cloudinary.com/{cloud}/image/upload/c_limit,w_900,q_auto,f_auto/{publicId}.{ext}`
class CloudinaryUrl {
  CloudinaryUrl._();

  static const String _marker = '/image/upload/';

  /// Returns [url] with a `c_limit,w_{width},q_auto,f_auto` transformation
  /// inserted. If [url] is not a Cloudinary delivery URL or already contains
  /// a transformation segment, it is returned unchanged.
  static String sized(String url, {required int width}) {
    if (url.isEmpty || width <= 0) return url;
    final int idx = url.indexOf(_marker);
    if (idx < 0) return url;

    final int after = idx + _marker.length;
    final String head = url.substring(0, after);
    final String tail = url.substring(after);

    // If a transformation is already present (typical pattern: `c_…,w_…/...`),
    // leave the URL alone so we don't stack conflicting params.
    final int slash = tail.indexOf('/');
    if (slash > 0) {
      final String firstSeg = tail.substring(0, slash);
      if (_looksLikeTransform(firstSeg)) return url;
    }

    return '${head}c_limit,w_$width,q_auto,f_auto/$tail';
  }

  static bool _looksLikeTransform(String seg) {
    // Cloudinary transformation segments are comma-joined `k_v` pairs.
    if (!seg.contains(',') && !seg.contains('_')) return false;
    for (final part in seg.split(',')) {
      if (!RegExp(r'^[a-z]+_').hasMatch(part)) return false;
    }
    return true;
  }
}
