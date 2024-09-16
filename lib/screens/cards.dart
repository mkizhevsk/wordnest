import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordnest/screens/card_form.dart';
import 'package:wordnest/design/colors.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/assets/constants.dart' as constants;
import 'package:wordnest/services/preferences_service.dart';

class CardTab extends StatefulWidget {
  const CardTab({super.key});

  @override
  State<StatefulWidget> createState() => CardTabState();
}

class CardTabState extends State<CardTab> {
  late AppDatabase db;
  bool _isFrontSide = true;

  int _deckId = 0;
  int _cardId = 0;
  String _frontText = "";
  String _backText = "";
  String _exampleText = "";

  List<Map<String, dynamic>> _decks = [];
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    db = AppDatabase.instance;

    _initializeDeckId();
    _fetchDecks();
  }

  Future<void> _initializeDeckId() async {
    final savedDeckId = await _preferencesService.getSelectedDeckId();
    if (savedDeckId != null) {
      _deckId = savedDeckId;
    } else {
      _deckId = 1;
      _preferencesService.saveSelectedDeckId(_deckId);
    }
    print('CardTabState: finish _initializeDeckId() with _deckId $_deckId');
    _fetchCardData();
  }

  Future<void> _fetchDecks() async {
    final decks = await db.getDecks();
    print('CardTabState: _fetchDecks() with decks ${decks.length}');
    setState(() {
      _decks = decks.map((deck) => {"id": deck.id, "name": deck.name}).toList();
    });
  }

  Future<void> _fetchCardData() async {
    print('CardTabState: _fetchCardData() for deckId $_deckId');
    try {
      final card = await db.getCardToLearn(_deckId);
      if (!mounted) return;
      setState(() {
        _cardId = card.id!;
        _frontText = card.front!;
        _backText = card.back!;
        _exampleText = card.example!;
      });
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('No unlearned cards available')) {
        if (!mounted) return;
        setState(() {
          _frontText = 'No unlearned cards available';
          _backText = '';
          _exampleText = '';
        });
      } else {
        print('Error fetching card data: $e');
      }
    }
  }

  Future<void> _saveSelectedDeckId(int deckId) async {
    await _preferencesService.saveSelectedDeckId(deckId);
  }

  Future<void> _updateStatusAndFetchNextCard(int status) async {
    var updatedCard = await db.getCard(_cardId);
    updatedCard.status = status;
    updatedCard.editDateTime = DateTime.now();
    await db.updateCardFromForm(updatedCard);
    setState(() {
      _fetchCardData();
    });
  }

  void _turnCard() {
    setState(() {
      _isFrontSide = !_isFrontSide;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /**
       * HEADER
       */
      appBar: AppBar(
        /**
         * Hamburger menu
         */
        leading: PopupMenuButton<int>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            // Handle menu item selection here
            if (value == 1) {
              print('one');
            } else if (value == 2) {
              // Exit the app
              SystemNavigator.pop();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 1,
              child: Text('Cards'),
            ),
            PopupMenuItem(
              value: 2,
              child: Text('Exit'),
            ),
          ],
        ),

        /**
         * Deck dropdawn
         */
        title: Center(
          child: DropdownButton<int>(
            value: _deckId,
            items: _decks.map((deck) {
              return DropdownMenuItem<int>(
                value: deck["id"],
                child: Text(deck["name"]),
              );
            }).toList(),
            onChanged: (int? newValue) {
              print('_deckId is now $_deckId');
              setState(() {
                _deckId = newValue!;
                _saveSelectedDeckId(newValue);
                _fetchCardData();
              });
            },
          ),
        ),
        centerTitle: true,

        /**
         * Add card button
         */
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add card',
            onPressed: () {
              print('actions add');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CardForm(0, '', '', ''),
                ),
              );
            },
          ),
        ],
      ),

      /**
       * BODY
       */
      body: Scaffold(
        backgroundColor: cardBodyBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              /**
               * Search row
               */
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: SearchRow(),
                ),
              ),

              /**
               * Card texts
               */
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ColoredBox(
                    color: cardBodyBackgroundColor,
                    child: GestureDetector(
                      onTap: () {
                        print('onTap');
                        _turnCard();
                      },
                      onLongPress: () {
                        print('onLongPress');
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CardForm(
                                _cardId, _frontText, _backText, _exampleText)));
                      },
                      child: Card(
                        child: _isFrontSide
                            ? _oneText(_frontText)
                            : _twoTexts(_backText, _exampleText),
                      ),
                    ),
                  ),
                ),
              ),

              /**
               * Two buttons
               */
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  top: 0.0,
                  right: 10.0,
                  bottom: 0.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                            onPressed: () {
                              print("onPressed next");
                              _updateStatusAndFetchNextCard(
                                  constants.cardIsNotLearned);
                            },
                            child: const Icon(Icons.navigate_next)),
                      ),
                      Expanded(
                        child: TextButton(
                            onPressed: () {
                              print("onPressed done");
                              _updateStatusAndFetchNextCard(
                                  constants.cardIsLearned);
                            },
                            child: const Icon(Icons.done)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oneText(String text) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: cardContentBackgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.center,
        child: Text(
          _deckId > 0 ? text : "",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _twoTexts(String text1, String text2) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: cardContentBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 0.0,
            ),
            child: Text(
              _deckId > 0 ? text1 : "",
              style: const TextStyle(color: cardContentFontColor, fontSize: 18),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: cardContentBackgroundColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 16.0,
            ),
            child: Text(
              _deckId > 0 ? text2 : "",
              style: const TextStyle(color: cardContentFontColor, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchRow extends StatelessWidget {
  const SearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: searchBackgroundColor,
              ),
              onChanged: (query) {
                // Handle the search logic here
                print('Search query: $query');
              },
            ),
          ),
        ],
      ),
    );
  }
}
