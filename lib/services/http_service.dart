import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wordnest/model/dto/card_dto.dart';
import 'package:wordnest/model/entity/card.dart';
import 'package:wordnest/utils/date_util.dart';
import 'package:wordnest/assets/constants.dart' as constants;
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/model/dto/deck_dto.dart';
import 'package:wordnest/model/entity/deck.dart';

class HttpService {
  final String apiUrl = '${constants.apiUrl}/api';

  HttpService();

  Future<List<DeckDTO>> syncDecks(List<DeckDTO> mobileDeckDTOs) async {
    final db = AppDatabase.instance;
    final tokenData = await db.getToken();

    final response = await http.post(
      Uri.parse('$apiUrl/decks/sync'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        if (tokenData != null)
          'Authorization': 'Bearer ${tokenData[constants.accessTokenField]}',
      },
      body: jsonEncode(mobileDeckDTOs),
    );

    String responseBody = utf8.decode(response.bodyBytes);
    //print("responseBody: " + responseBody);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(responseBody);
      List<DeckDTO> deckDTOList =
          body.map((dynamic item) => DeckDTO.fromJson(item)).toList();
      print("deckDTOList.length ${deckDTOList.length}");
      return deckDTOList;
    } else {
      throw Exception('Failed to load cards');
    }
  }

  Future<void> createOrUpdateDeck(DeckEntity deckEntity) async {
    final db = AppDatabase.instance;
    final tokenData = await db.getToken();
    var deckDTO = DeckDTO.fromEntity(deckEntity, []);

    Uri url = Uri.parse('$apiUrl/decks');
    http.Response response;

    if (deckEntity.id == 0) {
      // Create a new deck
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (tokenData != null)
            'Authorization': 'Bearer ${tokenData[constants.accessTokenField]}',
        },
        body: jsonEncode(deckDTO),
      );
    } else {
      // Update an existing deck
      response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (tokenData != null)
            'Authorization': 'Bearer ${tokenData[constants.accessTokenField]}',
        },
        body: jsonEncode(deckDTO),
      );
    }

    if (response.statusCode == 200) {
      print('Deck ${deckEntity.id == 0 ? "created" : "updated"} successfully');
    } else {
      throw Exception('Failed to create/update deck');
    }
  }

  Future<List<CardEntity>> getCards() async {
    final response = await http.get(
      Uri.parse('$apiUrl/cards'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    String responseBody = utf8.decode(response.bodyBytes);
    print(responseBody);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(responseBody);
      List<CardDTO> cardDTOList =
          body.map((dynamic item) => CardDTO.fromJson(item)).toList();

      List<CardEntity> cards = [];

      for (var cardDTO in cardDTOList) {
        CardEntity card = CardEntity(
          internalCode: cardDTO.internalCode,
          editDateTime: DateUtil.stringToDateTime(cardDTO.editDateTime),
          front: cardDTO.front,
          back: cardDTO.back,
          example: cardDTO.example,
          status: cardDTO.status,
        );

        cards.add(card);
      }

      return cards;
    } else {
      throw Exception('Failed to load cards');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(Uri.parse('$apiUrl$endpoint'));

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return response;
    } else {
      throw Exception('Failed to post data');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to update data');
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$apiUrl$endpoint'));

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to delete data');
    }
  }
}
