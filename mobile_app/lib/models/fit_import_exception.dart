/// A controlled message suitable for display, never a raw server response.
class FitImportException implements Exception {
  const FitImportException(this.message);
  final String message;
}
