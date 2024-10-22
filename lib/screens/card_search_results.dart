import 'package:flutter/material.dart';
import 'package:wordnest/model/entity/card.dart';
import 'package:wordnest/utils/event_bus.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<CardEntity> results;
  final int deckId;

  const SearchResultsScreen(
      {super.key, required this.results, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final card = results[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: InkWell(
              onTap: () {
                // Emit the event with the selected cardId
                eventBus.fire(CardSelectedEvent(cardId: card.id ?? 0));

                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Row: Front and Back
                    Text(
                      '${card.front} - ${card.back}',
                      style: const TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    // Second Row: Example
                    Text(
                      card.example ?? '',
                      style:
                          const TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardSelectedEvent {
  final int cardId;

  CardSelectedEvent({required this.cardId});
}
