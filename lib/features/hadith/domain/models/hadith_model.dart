class HadithModel {
  final String id;
  final String arabic;
  final String bangla;
  final String narrator;
  final String source;
  final String bookReference;

  const HadithModel({
    required this.id,
    required this.arabic,
    required this.bangla,
    required this.narrator,
    required this.source,
    required this.bookReference,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) => HadithModel(
        id: (json['id'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        bangla: (json['bangla'] ?? '').toString(),
        narrator: (json['narrator'] ?? '').toString(),
        source: (json['source'] ?? '').toString(),
        bookReference: (json['bookReference'] ?? '').toString(),
      );

  /// A hadith is only displayable when it carries its attribution. An entry
  /// without a source is a quote, not a hadith, and must never be shown as one.
  bool get isAttributed =>
      bangla.isNotEmpty && source.isNotEmpty && bookReference.isNotEmpty;
}
