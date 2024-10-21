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
      _logger.info(
          'start fetchAndSyncCards, fetched ${localDecks.length} decks from local database');

      await syncDecksWithServer(localDecks);
    } catch (error) {
      _logger.severe('Error fetching or syncing decks: $error');
    }
  }

  Future<void> syncDecksWithServer(List<DeckEntity> localDecks) async {
    try {
      var localDeckDTOs = await _getLocalDeckDTOs(localDecks);
      _logger.info('localDeckDTOs ${localDeckDTOs.length}');

      List<DeckDTO> webDeckDtoList = await httpService.syncDecks(localDeckDTOs);
      _logger.info('Received webDeckDtos: ${webDeckDtoList.length}');

      for (var webDeckDto in webDeckDtoList) {
        _logger.fine(
            'WebDeckDto: ${webDeckDto.name}, ${webDeckDto.internalCode}, ${webDeckDto.editDateTime}, ${webDeckDto.cards.length}, ${webDeckDto.deleted}');

        await _processDeck(localDecks, webDeckDto);
      }

      await _processWebDeckCards(webDeckDtoList);
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
    _logger.info("_processDeck");
    var webDateTime = DateUtil.stringToDateTime(webDeckDto.editDateTime);
    bool isPresent = false;

    for (var localDeck in localDecks) {
      if (localDeck.internalCode == webDeckDto.internalCode) {
        isPresent = true;

        var trimedMobileDate = DateUtil.trimAndConvertToDateTime(
            localDeck.editDateTime, webDateTime);

        if (webDeckDto.deleted) {
          await _deleteDeck(localDeck.internalCode);
        } else if (webDateTime.isAfter(trimedMobileDate)) {
          await _updateDeck(localDeck, webDeckDto, webDateTime);
        }
        break;
      }
    }

    if (!isPresent && !webDeckDto.deleted) {
      await _createDeck(webDeckDto, webDateTime);
    }
  }

  Future<void> _deleteDeck(String internalCode) async {
    _logger.info('_deleteDeck start: inernalCode $internalCode');
    DeckEntity deck =
        await AppDatabase.instance.getDeckByInternalCode(internalCode);
    var deckName = deck.name;

    await AppDatabase.instance.deleteDeckById(deck.id!);
    _logger.info('Deck $deckName was deleted');
  }

  Future<void> _updateDeck(
      DeckEntity deck, DeckDTO webDeckDto, DateTime webDateTime) async {
    _logger.info("_updateDeck start: ${webDeckDto.name}");
    try {
      deck.name = webDeckDto.name;
      deck.editDateTime = webDateTime;
      await AppDatabase.instance.updateDeck(deck);
      _logger.info('Deck ${deck.name} was updated, ${deck.editDateTime}');
    } catch (error) {
      _logger.severe('Error updating deck ${deck.name}. Error: $error');
    }
  }

  Future<void> _createDeck(DeckDTO webDeckDto, DateTime webDateTime) async {
    _logger.info('_createDeck start: ${webDeckDto.name}');
    try {
      var deckEntity = DeckEntity(
        name: webDeckDto.name,
        internalCode: webDeckDto.internalCode,
        editDateTime: webDateTime,
      );
      await AppDatabase.instance.createDeck(deckEntity);
      _logger.info('Deck ${webDeckDto.name} was created');
    } catch (error) {
      _logger.severe('Error creating deck ${webDeckDto.name}. Error: $error');
    }
  }

  Future<void> _processWebDeckCards(List<DeckDTO> webDeckDtoList) async {
    List<CardEntity> localCards = await AppDatabase.instance.getCards();
    _logger.info(
        'Start _processWebDeckCards, fetched ${localCards.length} cards from local database');

    for (var card in localCards) {
      _logger.fine(
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
    CardEntity cardFromWeb = _createCardEntity(webCardDto, deck.id!);

    for (var localCard in localCards) {
      var trimedMobileDate = DateUtil.trimAndConvertToDateTime(
          localCard.editDateTime, cardFromWeb.editDateTime);

      if (localCard.internalCode == cardFromWeb.internalCode) {
        isPresent = true;
        if (webCardDto.deleted) {
          await _deleteCard(localCard.internalCode);
        } else if (cardFromWeb.editDateTime.isAfter(trimedMobileDate)) {
          await _updateCard(cardFromWeb);
        }
        break;
      }
    }

    if (!isPresent && !webCardDto.deleted) {
      await AppDatabase.instance.createCard(cardFromWeb);
      _logger.info(
          'Created new local card:  ${cardFromWeb.id}, ${cardFromWeb.deckId}, ${cardFromWeb.internalCode}, ${cardFromWeb.editDateTime}, ${cardFromWeb.front}, ${cardFromWeb.back}, ${cardFromWeb.example}, ${cardFromWeb.status}');
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
    _logger.info('_deleteCard start: inernalCode $internalCode');
    await AppDatabase.instance.deleteCardByInternalCode(internalCode);
    _logger.info("Card with internalCode $internalCode was deleted");
  }

  Future<void> _updateCard(CardEntity card) async {
    _logger.info('_updateCard start: ${card.front}');
    await AppDatabase.instance.updateCard(card);
    _logger.info("Card ${card.front} was updated, ${card.editDateTime}");
  }
}
