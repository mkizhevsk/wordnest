import 'package:flutter/material.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/model/entity/card.dart';
import 'package:wordnest/utils/string_random_generator.dart';
import 'package:wordnest/main.dart';

class CardForm extends StatefulWidget {
  final int _deckId;
  final int _cardId;
  final String _front;
  final String _back;
  final String _example;

  const CardForm(
      this._deckId, this._cardId, this._front, this._back, this._example,
      {super.key});

  @override
  State<StatefulWidget> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final AppDatabase db = AppDatabase.instance;
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  late final CardEntity card;

  static const double paddingValue = 8.0;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _frontController.text = widget._front;
    _backController.text = widget._back;
    _exampleController.text = widget._example;
  }

  Future<int> _createCard() async {
    var card = CardEntity(
      deckId: widget._deckId,
      internalCode: StringRandomGenerator.instance.getValue(),
      editDateTime: DateTime.now(),
      front: _frontController.text,
      back: _backController.text,
      example: _exampleController.text,
      status: 0,
    );
    var newCard = await db.createCard(card);
    return newCard.id!;
  }

  Future<int> _updateCard() async {
    var updatedCard = await db.getCard(widget._cardId);
    updatedCard.editDateTime = DateTime.now();
    updatedCard.front = _frontController.text;
    updatedCard.back = _backController.text;
    updatedCard.example = _exampleController.text;
    await db.updateCardFromForm(updatedCard);
    return updatedCard.id!;
  }

  @override
  Widget build(BuildContext context) {
    // print('cardId ${widget.cardId}');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(paddingValue),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(paddingValue),
              child: TextField(
                controller: _frontController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Front',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(paddingValue),
              child: TextField(
                controller: _backController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Back',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(paddingValue),
              child: TextField(
                controller: _exampleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Example',
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                // print('widget.cardId ' + widget.cardId.toString());
                int cardId;
                if (widget._cardId == 0) {
                  cardId = await _createCard();
                } else {
                  cardId = await _updateCard();
                }
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
