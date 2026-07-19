/// The authenticated user, as the app understands them.
///
/// Deliberately minimal: this release stores no profile data beyond what the
/// server returns from `/auth/me`.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final int id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        email: (json['email'] ?? '').toString(),
        displayName: json['displayName'] as String?,
        emailVerified: json['emailVerified'] == true,
      );

  /// Bangla-friendly label for greetings — falls back to the email local part.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
