import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordnest/screens/card_form.dart';
import 'package:wordnest/design/colors.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/assets/constants.dart' as constants;

class CardTab extends StatefulWidget {
  const CardTab({super.key});

  @override
  State<StatefulWidget> createState() => CardTabState();
}

class CardTabState extends State<CardTab> {
  late AppDatabase db;
  bool _isFrontSide = true;

  int _deckId = 1;
  int _cardId = 0;
  String _frontText = "";
  String _backText = "";
  String _exampleText = "";

  // Test deck data (IDs and names)
  List<Map<String, dynamic>> _decks = [
    {"id": 1, "name": "Deck 1"}, // Test deck 1
    {"id": 2, "name": "Deck 2"}, // Test deck 2
  ];

  @override
  void initState() {
    super.initState();
    db = AppDatabase.instance;
    _fetchCardData();
  }

  Future<void> _fetchCardData() async {
    print('CardTabState _fetchCardData() for deckId $_deckId');
    final card = await db.getCardToLearn(_deckId);

    setState(() {
      _cardId = card.id!;
      _frontText = card.front!;
      _backText = card.back!;
      _exampleText = card.example!;
    });
  }

  Future<void> _nextCard(int status) async {
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
      appBar: AppBar(
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
        title: const Text('My space'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add card',
            onPressed: () {
              print('actions add');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CardForm(),
                ),
              );
            },
          ),
        ],
      ),
      body: Scaffold(
        backgroundColor: cardBodyBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: SearchRow(),
                ),
              ),
              // Dropdown and button row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _deckId,
                        items: _decks.map((deck) {
                          return DropdownMenuItem<int>(
                            value: deck["id"],
                            child: Text(deck["name"]),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _deckId = newValue!;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Create deck',
                      onPressed: () {
                        // Handle create deck logic
                        print('Create new deck');
                        // You can navigate to a new screen or show a dialog to create a deck
                      },
                    ),
                  ],
                ),
              ),
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
              // two buttons
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
                              _nextCard(constants.cardIsNotLearned);
                            },
                            child: const Icon(Icons.navigate_next)),
                      ),
                      Expanded(
                        child: TextButton(
                            onPressed: () {
                              print("onPressed done");
                              _nextCard(constants.cardIsLearned);
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
          text,
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
              text1,
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
              text2,
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
