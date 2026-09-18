class ContentManifest {
  final int schemaVersion;
  final int contentVersion;
  final String language;
  final String secondaryAudioLanguage;
  final String learningLanguage;

  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.language,
    required this.secondaryAudioLanguage,
    required this.learningLanguage,
  });

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    return ContentManifest(
      schemaVersion: json['schemaVersion'] as int,
      contentVersion: json['contentVersion'] as int,
      language: json['language'] as String,
      secondaryAudioLanguage: json['secondaryAudioLanguage'] as String,
      learningLanguage: json['learningLanguage'] as String,
    );
  }
}
