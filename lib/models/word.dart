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
      english: json['english'],
      pronunciation: json['pronunciation'],
      partOfSpeech: json['part_of_speech'],
      englishDefinition: json['english_definition'],
      oromoTranslation: json['oromo_translation'],
    );
  }
}
