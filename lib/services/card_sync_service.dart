import 'package:wordnest/services/http_service.dart';
import 'package:wordnest/model/entity/card.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/model/dto/card_dto.dart';
import 'package:wordnest/utils/date_util.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:wordnest/model/entity/deck.dart';
import 'package:wordnest/model/dto/deck_dto.dart';
import 'package:wordnest/services/auth_service.dart';

class CardSyncService {
  final Logger _logger = Logger('CardSyncService');
  final HttpService httpService = HttpService();
  final AuthService authService = AuthService();

  Future<void> fetchAndSyncCards() async {
    try {
      List<DeckEntity> localDecks = await AppDatabase.instance.getDecks();
      print(
          'start fetchAndSyncCards, fetched ${localDecks.length} decks from local database');

      // Sync fetched local decks with server
      await syncDecksWithServer(localDecks);
    } catch (error) {
      _logger.severe('Error fetching or syncing decks: $error');
    }
  }

  Future<void> syncDecksWithServer(List<DeckEntity> localDecks) async {
    try {
      var localDeckDTOs = await _getLocalDeckDTOs(localDecks);
      print('localDeckDTOs ${localDeckDTOs.length}');

      List<DeckDTO> webDeckDtoList = await httpService.syncDecks(localDeckDTOs);
      print('Received webDeckDtos: ${webDeckDtoList.length}');

      for (var webDeckDto in webDeckDtoList) {
        _logger.fine(
            'WebDeckDto: ${webDeckDto.name}, ${webDeckDto.internalCode}, ${webDeckDto.editDateTime}, ${webDeckDto.cards.length}, ${webDeckDto.deleted}');

        await _processDeck(localDecks, webDeckDto);
      }

      await _processWebDecks(webDeckDtoList);
    } catch (error) {
      _logger.severe('Error syncing decks with server: $error');
    }
  }

  Future<List<DeckDTO>> _getLocalDeckDTOs(List<DeckEntity> localDecks) async {
    List<DeckDTO> localDeckDTOs = [];
    List<CardEntity> localCards = await AppDatabase.instance.getCards();
    _logger.info(
        'Start _getLocalDeckDTOs, fetched ${localCards.length} cards from local database');

    for (var deck in localDecks) {
      List<CardDTO> deckCardDTOs = [];
      for (var card in localCards) {
        if (card.deckId == deck.id) {
          var cardDTO = CardDTO.fromEntity(card);
          deckCardDTOs.add(cardDTO);
        }
      }

      DeckDTO deckDTO = DeckDTO.fromEntity(deck, deckCardDTOs);

      localDeckDTOs.add(deckDTO);
    }

    return localDeckDTOs;
  }

  Future<void> _processDeck(
      List<DeckEntity> localDecks, DeckDTO webDeckDto) async {
    print("_processDeck");
    var webDeckEditDateTime =
        DateUtil.stringToDateTime(webDeckDto.editDateTime);
    bool isPresent = false;
    //DeckEntity webDeck = _createDeckEntity(webDeckDto);

    for (var localDeck in localDecks) {
      if (localDeck.internalCode == webDeckDto.internalCode) {
        isPresent = true;
        if (webDeckDto.deleted) {
          // If the deck is marked as deleted, remove it from the local database
          print("_deleteDeck");
          await _deleteDeck(localDeck.internalCode);
        } else if (webDeckEditDateTime.isAfter(localDeck.editDateTime)) {
          print("_updateDeck");
          // If the server's version is newer, update the local deck
          await _updateDeck(webDeckDto);
        }
        print("break");
        break;
      }
    }

    if (!isPresent && !webDeckDto.deleted) {
      // If the deck is not present and not deleted, create a new one
      await _createDeck(webDeckDto, webDeckEditDateTime);
    }
  }

  Future<void> _deleteDeck(String internalCode) async {
    // Implement logic to delete the deck from the local database using the internalCode
  }

  Future<void> _updateDeck(DeckDTO deck) async {
    // Implement logic to update the deck in the local database
  }

  Future<void> _createDeck(DeckDTO deckDTO, DateTime editDateTime) async {
    try {
      var deckEntity = DeckEntity(
        name: deckDTO.name,
        internalCode: deckDTO.internalCode,
        editDateTime: editDateTime,
      );
      await AppDatabase.instance.createDeck(deckEntity);
      _logger.info('Deck created with internalCode: ${deckDTO.internalCode}');
    } catch (error) {
      _logger.severe(
          'Error creating deck with internalCode: ${deckDTO.internalCode}. Error: $error');
    }
  }

  Future<void> _processWebDecks(List<DeckDTO> webDeckDtoList) async {
    List<CardEntity> localCards = await AppDatabase.instance.getCards();
    print(
        'Start _processWebDecks, fetched ${localCards.length} cards from local database');
    for (var card in localCards) {
      print(
          '${card.id}, ${card.deckId}, ${card.internalCode}, ${card.editDateTime}, ${card.front}, ${card.back}, ${card.example}, ${card.status}');
    }

    for (var webDeckDto in webDeckDtoList) {
      for (var webCardDto in webDeckDto.cards) {
        await _processCard(localCards, webCardDto, webDeckDto.internalCode);
      }
    }
  }

  Future<void> _processCard(List<CardEntity> localCards, CardDTO webCardDto,
      String deckInternalCode) async {
    DeckEntity deck =
        await AppDatabase.instance.getDeckByInternalCode(deckInternalCode);
    bool isPresent = false;
    CardEntity card = _createCardEntity(webCardDto, deck.id!);

    for (var localCard in localCards) {
      if (localCard.internalCode == card.internalCode) {
        isPresent = true;
        if (webCardDto.deleted) {
          await _deleteCard(localCard.internalCode);
        } else if (card.editDateTime.isAfter(localCard.editDateTime)) {
          await AppDatabase.instance.updateCard(card);
          print('Updated local card with internalCode: ${card.internalCode}');
        }
        break;
      }
    }

    if (!isPresent && !webCardDto.deleted) {
      await AppDatabase.instance.createCard(card);
      print(
          'Created new local card:  ${card.id}, ${card.deckId}, ${card.internalCode}, ${card.editDateTime}, ${card.front}, ${card.back}, ${card.example}, ${card.status}');
    }
  }

  CardEntity _createCardEntity(CardDTO cardDto, int deckId) {
    return CardEntity(
      deckId: deckId,
      internalCode: cardDto.internalCode,
      editDateTime: DateUtil.stringToDateTime(cardDto.editDateTime),
      front: cardDto.front,
      back: cardDto.back,
      example: cardDto.example,
      status: cardDto.status,
    );
  }

  Future<void> _deleteCard(String internalCode) async {
    var result =
        await AppDatabase.instance.deleteCardByInternalCode(internalCode);
    if (result > 0) {
      _logger.info("Card with internalCode $internalCode was deleted");
    }
  }
}
