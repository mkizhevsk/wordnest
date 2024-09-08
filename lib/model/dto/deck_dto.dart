import 'package:wordnest/model/entity/deck.dart';
import 'package:wordnest/model/dto/card_dto.dart';
import 'package:wordnest/utils/date_util.dart';

class DeckDTO {
  final String name;
  final String internalCode;
  final String editDateTime;
  final bool deleted;
  final List<CardDTO> cards;

  DeckDTO({
    required this.name,
    required this.internalCode,
    required this.editDateTime,
    required this.deleted,
    required this.cards,
  });

  factory DeckDTO.fromJson(Map<String, dynamic> json) {
    return DeckDTO(
      internalCode: json['internalCode'],
      editDateTime: json['editDateTime'],
      name: json['name'],
      deleted: json['deleted'] as bool,
      cards: (json['cards'] as List<dynamic>)
          .map((cardJson) => CardDTO.fromJson(cardJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internalCode': internalCode,
      'editDateTime': editDateTime,
      'name': name,
      'deleted': deleted,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }

  static DeckDTO fromEntity(DeckEntity entity, List<CardDTO> cards) {
    return DeckDTO(
      internalCode: entity.internalCode,
      name: entity.name,
      editDateTime: DateUtil.dateTimeToString(entity.editDateTime),
      deleted: false,
      cards: cards,
    );
  }
}
