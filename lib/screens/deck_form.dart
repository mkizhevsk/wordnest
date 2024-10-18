import 'package:flutter/material.dart';
import 'package:wordnest/database/app_database.dart';
import 'package:wordnest/model/entity/deck.dart';
import 'package:wordnest/utils/string_random_generator.dart';
import 'package:wordnest/services/http_service.dart';

class AddDeckScreen extends StatefulWidget {
  final int deckId;
  final Future<void> Function()? onDeckSaved; // Callback for refreshing decks

  const AddDeckScreen({
    super.key,
    required this.deckId,
    this.onDeckSaved,
  }); // Pass the key parameter to the superclass

  @override
  AddDeckScreenState createState() => AddDeckScreenState();
}

class AddDeckScreenState extends State<AddDeckScreen> {
  final HttpService httpService = HttpService();
  final _deckNameController = TextEditingController();
  late AppDatabase db;

  @override
  void initState() {
    super.initState();
    db = AppDatabase.instance; // Initialize your database instance

    // If deckId > 0, load the deck data
    if (widget.deckId > 0) {
      _loadDeckData(widget.deckId);
    }
  }

  Future<void> _loadDeckData(int id) async {
    try {
      DeckEntity deck = await db.getDeckById(id); // Fetch the deck by ID
      _deckNameController.text = deck.name; // Set the name in the controller
    } catch (e) {
      ('Error loading deck: $e'); // Handle any errors
    }
  }

  Future<void> _saveDeck() async {
    String deckName = _deckNameController.text.trim();
    if (deckName.isNotEmpty) {
      DeckEntity deckEntity;

      if (widget.deckId == 0) {
        // Insert a new deck without specifying an ID
        DeckEntity createdEntity = DeckEntity(
          name: deckName,
          internalCode: StringRandomGenerator.instance.getValue(),
          editDateTime: DateTime.now(),
        );
        deckEntity =
            await db.createDeck(createdEntity); // Use insertDeck method here
      } else {
        DeckEntity ddd1 = await db.getDeckById(widget.deckId);
        print('here1 ${ddd1.internalCode}');

        // Update an existing deck with the given ID
        DeckEntity updatedEntity = DeckEntity(
          id: widget.deckId,
          name: deckName,
          internalCode: '',
          editDateTime: DateTime.now(),
        );
        deckEntity = await db
            .updateDeck(updatedEntity); // Use saveDeck method here for update

        DeckEntity ddd2 = await db.getDeckById(widget.deckId);
        print('here2 ${ddd2.internalCode}');
      }

      // Sync with the server in the background (no await)
      print('here5');
      print(deckEntity.internalCode);
      HttpService().createOrUpdateDeck(deckEntity, widget.deckId);

      if (widget.onDeckSaved != null) {
        await widget.onDeckSaved!(); // Call the callback to refresh the decks
      }

      Navigator.of(context).pop(); // Close the screen after saving
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
              onPressed: _saveDeck,
              child: const Text('Save Deck'),
            ),
          ],
        ),
      ),
    );
  }
}
