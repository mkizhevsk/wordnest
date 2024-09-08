import 'package:wordnest/assets/constants.dart' as constants;

class CardEntity {
  int? id;
  int? deckId;
  late String internalCode;
  late DateTime editDateTime;
  String? front;
  String? back;
  String? example;
  int? status; // Состояние: 0 - не выучено, 1 - выучено

  CardEntity({
    this.id,
    this.deckId,
    required this.internalCode,
    required this.editDateTime,
    this.front,
    this.back,
    this.example,
    this.status,
  });

  CardEntity.empty();

  static CardEntity fromJson(Map<String, dynamic> json) => CardEntity(
        id: json[constants.cardIdField] as int,
        deckId: json[constants.cardDeckIdField] as int,
        internalCode: json[constants.cardInternalCodeField] as String,
        editDateTime:
            DateTime.parse(json[constants.cardEditDateTimeField] as String),
        front: json[constants.cardFrontField] as String?,
        back: json[constants.cardBackField] as String?,
        example: json[constants.cardExampleField] as String?,
        status: json[constants.cardStatusField] as int?,
      );

  Map<String, dynamic> toJson() => {
        constants.cardIdField: id,
        constants.cardDeckIdField: deckId,
        constants.cardInternalCodeField: internalCode,
        constants.cardEditDateTimeField: editDateTime.toIso8601String(),
        constants.cardFrontField: front,
        constants.cardBackField: back,
        constants.cardExampleField: example,
        constants.cardStatusField: status,
      };

  CardEntity copyWith({
    int? id,
    String? internalCode,
    DateTime? editDateTime,
    String? front,
    String? back,
    String? example,
    int? status,
  }) =>
      CardEntity(
        id: id ?? this.id,
        internalCode: internalCode ?? this.internalCode,
        editDateTime: editDateTime ?? this.editDateTime,
        front: front ?? this.front,
        back: back ?? this.back,
        example: example ?? this.example,
        status: status ?? this.status,
      );

  @override
  String toString() {
    return '$id, $internalCode, $editDateTime, $front, $back, $example, $status';
  }
}
