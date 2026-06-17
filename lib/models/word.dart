class Word {
  final String english;
  final String pronunciation;
  final String partOfSpeech;
  final String englishDefinition;
  final String oromoTranslation;
  bool isFavorite;

  Word({
    required this.english,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.englishDefinition,
    required this.oromoTranslation,
    this.isFavorite = false,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      english:           (json['english']            as String?) ?? '',
      pronunciation:     (json['pronunciation']       as String?) ?? '',
      partOfSpeech:      (json['part_of_speech']      as String?) ?? '',
      englishDefinition: (json['english_definition']  as String?) ?? '',
      oromoTranslation:  (json['oromo_translation']   as String?) ?? '',
    );
  }

  /// Returns true only if the word has the minimum required fields.
  /// Used to filter out corrupt or incomplete entries after fromJson.
  bool get isValid => english.trim().isNotEmpty;
}