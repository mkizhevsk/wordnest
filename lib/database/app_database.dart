import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:wordnest/model/entity/card.dart';
import 'package:wordnest/assets/constants.dart' as constants;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wordnest/model/entity/deck.dart';

const String fileName = "tasks_database.db";

class AppDatabase {
  AppDatabase._init();

  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB(fileName);
    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${constants.deckTableName} (
        ${constants.deckIdField} ${constants.idType},
        ${constants.deckNameField} ${constants.textType},
        ${constants.deckInternalCodeField} ${constants.textType},
        ${constants.deckEditDateTimeField} ${constants.textType}
      )
    ''');

    await db.execute('''
      CREATE TABLE ${constants.cardTableName} (
        ${constants.cardIdField} ${constants.idType},
        ${constants.cardDeckIdField} ${constants.intTypeNullable},
        ${constants.cardInternalCodeField} ${constants.textType},
        ${constants.cardEditDateTimeField} ${constants.textType},
        ${constants.cardFrontField} ${constants.textTypeNullable},
        ${constants.cardBackField} ${constants.textTypeNullable},
        ${constants.cardExampleField} ${constants.textTypeNullable},
        ${constants.cardStatusField} ${constants.intTypeNullable}
      )
    ''');

    await db.execute('''
      CREATE TABLE ${constants.tokenTableName} (
        ${constants.tokenIdField} ${constants.idType},
        ${constants.accessTokenField} ${constants.textType},
        ${constants.refreshTokenField} ${constants.textType},
        ${constants.tokenTypeField} ${constants.textType},
        ${constants.expiryDateField} ${constants.textType}
      )
    ''');
  }

  Future<Database> _initializeDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Deck
  Future<DeckEntity> createDeck(DeckEntity deck) async {
    final db = await instance.database;
    // Insert new deck without id
    final id = await db.insert(constants.deckTableName, deck.toJson());
    return deck.copyWith(id: id); // Return the new deck with generated ID
  }

  // Deck Update
  Future<DeckEntity> updateDeck(DeckEntity deck) async {
    final db = await instance.database;

    if (deck.id != null && deck.id! > 0) {
      // Update only the name of the existing deck
      await db.update(
        constants.deckTableName,
        {constants.deckNameField: deck.name}, // Only update the name field
        where: '${constants.deckIdField} = ?',
        whereArgs: [deck.id],
      );
      return deck; // Return the updated deck
    } else {
      throw Exception('Invalid deck ID for update');
    }
  }

  Future<List<DeckEntity>> getDecks() async {
    final db = await database;

    // Fetching all decks from the 'decks' table
    final List<Map<String, dynamic>> deckMaps =
        await db.query(constants.deckTableName);

    // Converting the list of maps to a list of DeckEntity objects
    return List.generate(deckMaps.length, (i) {
      return DeckEntity.fromJson(deckMaps[i]);
    });
  }

  Future<DeckEntity> getDeckById(int id) async {
    final db = await instance.database;

    // Query the deck table to find a deck with the specified ID
    final result = await db.query(
      constants.deckTableName, // Use the constant for the table name
      where: '${constants.deckIdField} = ?', // Filter by ID
      whereArgs: [id],
    );

    // Check if any deck was found and return it as a DeckEntity
    if (result.isNotEmpty) {
      return DeckEntity.fromJson(result.first);
    } else {
      throw Exception('No deck found with ID $id');
    }
  }

  Future<DeckEntity> getDeckByInternalCode(String internalCode) async {
    final db = await instance.database;

    // Query the deck table to find a deck with the specified internal code
    final result = await db.query(
      'deck', // Assuming the table name is 'deck'
      where: 'internal_code = ?',
      whereArgs: [internalCode],
    );

    // Check if any deck was found and return it as a DeckEntity
    if (result.isNotEmpty) {
      return DeckEntity.fromJson(result.first);
    } else {
      throw Exception('No deck found with internal code $internalCode');
    }
  }

  // Card
  Future<CardEntity> createCard(CardEntity card) async {
    final db = await instance.database;
    final id = await db.insert(constants.cardTableName, card.toJson());
    return card.copyWith(id: id);
  }

  Future<CardEntity> getCard(int cardId) async {
    final db = await instance.database;
    final result = await db
        .query(constants.cardTableName, where: 'id = ?', whereArgs: [cardId]);
    return result.map((json) => CardEntity.fromJson(json)).first;
  }

  Future<CardEntity> updateCard(CardEntity card) async {
    final db = await instance.database;
    await db.update(
      constants.cardTableName,
      card.toJson(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
    return card;
  }

  Future<int> deleteCardByInternalCode(String internalCode) async {
    final db = await instance.database;
    return await db.delete(
      constants.cardTableName,
      where: '${constants.cardInternalCodeField} = ?',
      whereArgs: [internalCode],
    );
  }

  Future<List<CardEntity>> getCards() async {
    final db = await instance.database;
    final result = await db.query(constants.cardTableName,
        orderBy: "${constants.cardEditDateTimeField} DESC");
    return result.map((json) => CardEntity.fromJson(json)).toList();
  }

  Future<List<CardEntity>> getCardsByDeck(int deckId) async {
    final db = await instance.database;

    final result = await db.query(
      constants.cardTableName,
      where: '${constants.cardDeckIdField} = ?',
      whereArgs: [deckId],
      orderBy: '${constants.cardEditDateTimeField} DESC',
    );

    // Map the results to a list of CardEntity objects
    return result.map((json) => CardEntity.fromJson(json)).toList();
  }

  Future<CardEntity> getCardToLearn(int deckId) async {
    print('AppDatabase getCardToLearn for deckId $deckId');
    var cards = await getCardsByDeck(deckId);
    print('cards in deck: ${cards.length}');
    // for (var card in cards) {
    //   print(card);
    // }
    var currentDate = DateTime.now();
    var formattedCurrentDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    var unlearnedCards = cards
        .where((card) => card.status == constants.cardIsNotLearned)
        .where((card) => !isSameDay(card.editDateTime, formattedCurrentDate))
        .toList();
    print('unlearned cards: ${unlearnedCards.length}');
    unlearnedCards.sort((a, b) => a.editDateTime.compareTo(b.editDateTime));
    if (unlearnedCards.isNotEmpty) {
      return unlearnedCards.first;
    } else {
      throw Exception('No unlearned cards available');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<int> updateCardFromForm(CardEntity card) async {
    print('updateCardFromForm, cardId = ${card.id}');
    final db = await instance.database;
    return await db.update(
      constants.cardTableName,
      card.toJson(),
      where: "${constants.cardIdField} = ?",
      whereArgs: [card.id],
    );
  }

  Future<void> saveToken(String accessToken, String refreshToken) async {
    final db = await instance.database;

    // Decode the refresh token to extract the expiration date
    Map<String, dynamic> decodedToken = JwtDecoder.decode(refreshToken);
    String expiryDate =
        DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000)
            .toIso8601String();
    print("New refresh token expires at: $expiryDate");

    // Create the token data map
    final tokenData = {
      constants.accessTokenField: accessToken,
      constants.refreshTokenField: refreshToken,
      constants.tokenTypeField: 'Bearer', // Assuming the token type is Bearer
      constants.expiryDateField: expiryDate,
    };

    // Clear previous tokens
    await db.delete(constants.tokenTableName);

    // Insert new token
    await db.insert(constants.tokenTableName, tokenData);
  }

  Future<Map<String, String>?> getToken() async {
    final db = await instance.database;
    final result = await db.query(constants.tokenTableName);
    if (result.isNotEmpty) {
      return {
        constants.accessTokenField:
            result.first[constants.accessTokenField] as String,
        constants.refreshTokenField:
            result.first[constants.refreshTokenField] as String,
        constants.tokenTypeField:
            result.first[constants.tokenTypeField] as String,
        constants.expiryDateField:
            result.first[constants.expiryDateField] as String,
      };
    }
    return null;
  }

  Future<void> deleteToken() async {
    final db = await instance.database;
    await db.delete(constants.tokenTableName);
  }
}
