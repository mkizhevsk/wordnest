import 'package:flutter/material.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/assets/constants.dart' as constants;
import 'package:wordnest/model/entity/deck.dart';
import 'package:wordnest/utils/string_random_generator.dart';

class AddDeckScreen extends StatefulWidget {
  @override
  _AddDeckScreenState createState() => _AddDeckScreenState();
}

class _AddDeckScreenState extends State<AddDeckScreen> {
  final _deckNameController = TextEditingController();
  late AppDatabase db;

  @override
  void initState() {
    super.initState();
    db = AppDatabase.instance; // Initialize your database instance
  }

  Future<void> _saveNewDeck() async {
    String deckName = _deckNameController.text.trim();
    if (deckName.isNotEmpty) {
      // Create a new DeckEntity object
      DeckEntity newDeck = DeckEntity(
        name: deckName,
        internalCode: StringRandomGenerator.instance.getValue(),
        editDateTime: DateTime.now(),
      );

      // Use the createDeck method to save the new deck
      await db.createDeck(newDeck);

      // Close the screen after saving
      Navigator.of(context).pop();
    } else {
      print('Deck name cannot be empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Deck'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deckNameController,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNewDeck,
              child: const Text('Save Deck'),
            ),
          ],
        ),
      ),
    );
  }
}
