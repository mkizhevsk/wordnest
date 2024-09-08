const String deckIdJsonName = "id";
const String deckNameJsonName = "name";
const String deckInternalCodeJsonName = "internal_code";
const String deckEditDateTimeJsonName = "edit_date_time";
const String deckDeletedJsonName = "deleted";
const String deckCardsJsonName = "cards";

class DeckEntity {
  int? id;
  late String name;
  late String internalCode;
  late DateTime editDateTime;

  DeckEntity({
    this.id,
    required this.name,
    required this.internalCode,
    required this.editDateTime,
  });

  DeckEntity.empty();

  static DeckEntity fromJson(Map<String, dynamic> json) => DeckEntity(
        id: json[deckIdJsonName] as int?,
        name: json[deckNameJsonName] as String,
        internalCode: json[deckInternalCodeJsonName] as String,
        editDateTime: DateTime.parse(json[deckEditDateTimeJsonName] as String),
      );

  Map<String, dynamic> toJson() => {
        deckIdJsonName: id,
        deckNameJsonName: name,
        deckInternalCodeJsonName: internalCode,
        deckEditDateTimeJsonName: editDateTime.toIso8601String(),
      };

  DeckEntity copyWith({
    int? id,
    String? name,
    String? internalCode,
    DateTime? editDateTime,
  }) =>
      DeckEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        internalCode: internalCode ?? this.internalCode,
        editDateTime: editDateTime ?? this.editDateTime,
      );

  @override
  String toString() {
    return '$id, $name, $internalCode, $editDateTime';
  }
}
