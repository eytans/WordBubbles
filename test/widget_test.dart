import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wordbubbles/main.dart';
import 'package:wordbubbles/models/word_models.dart';
import 'package:wordbubbles/widgets/word_bubbles_game.dart';
import 'package:wordbubbles/widgets/animated_bubbles_layer.dart';
import 'package:wordbubbles/data/teachable_words_data.dart';

void main() {
  testWidgets('WordBubbles app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WordBubblesApp());
    
    // Pump a few frames to let the app initialize
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that our app loads with the title.
    expect(find.text('WordBubbles: Learn & Play'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.byIcon(Icons.emoji_emotions), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    
    // Verify that the app structure is correct
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(WordBubblesGame), findsOneWidget);
  });

  testWidgets('visual mode switches between emoji and photo cards', (WidgetTester tester) async {
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.emoji_emotions));
    await tester.pump();
    expect(find.text('Photo cards'), findsOneWidget);

    await tester.tap(find.text('Photo cards'));
    await tester.pump();

    expect(find.byIcon(Icons.photo_library), findsOneWidget);
    final layer = tester.widget<AnimatedBubblesLayer>(
      find.byType(AnimatedBubblesLayer),
    );
    expect(layer.showPhotoCards, isTrue);
  });
  
  testWidgets('WordBubbles app has correct theme', (WidgetTester tester) async {
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'WordBubbles: Learn & Play');
    expect(app.debugShowCheckedModeBanner, false);
  });
  
  testWidgets('WordBubbles game initializes without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    
    // Verify the game widget exists and doesn't throw errors
    expect(find.byType(WordBubblesGame), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Verify that the app has a gradient background
    expect(find.byType(Container), findsWidgets);
  });
  
  testWidgets('WordBubbles app structure test', (WidgetTester tester) async {
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    
    // Test that basic widgets are present
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
  });

  Future<void> tapBubble(WidgetTester tester, WordBubble bubble) async {
    final bubbleFinder = find.text(bubble.word.iconUrl);
    expect(bubbleFinder, findsOneWidget);
    
    // Tap the bubble
    await tester.tap(bubbleFinder);
    await tester.pump();
  }

  // Function to tap bubbles by finding their positions
  // ignore: unused_element
  Future<void> tapAllBubbles(WidgetTester tester, dynamic gameState) async {
    final bubbles = List.from(gameState.bubbles);
    for (final bubble in bubbles) {
      if (!bubble.isClicked) {
        // Tap at the bubble's center position
        await tapBubble(tester, bubble);
        
        // Wait for speech and cleanup
        await tester.pump(const Duration(milliseconds: 2500));
      }
    }
    
    // Wait for new bubbles to appear
    await tester.pump(const Duration(milliseconds: 600));
  }

// Ignored
  // testWidgets('Word bubble interaction test - press words, verify disappearance, and new image loading', (WidgetTester tester) async {
  //   // Build the app
  //   await tester.pumpWidget(const WordBubblesApp());
    
  //   // Allow the app to initialize completely
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 500));
    
  //   // Get the initial state
  //   final gameState = tester.state(find.byType(WordBubblesGame)) as dynamic;
  //   final initialImageUrl = gameState.currentBackgroundImage;
    
  //   // Verify initial setup - should have 3 word bubbles
  //   expect(gameState.bubbles.length, equals(3));
  //   expect(gameState.setsCompletedCount, equals(0));
  //   expect(gameState.wordsClickedCount, equals(0));
    
  //   // Test Set 1: Press 3 words, verify they disappear, new ones appear
  //   print('Testing Set 1...');
  //   await tapAllBubbles(tester, gameState);
    
  //   // Verify new bubbles appeared and set count increased
  //   expect(gameState.bubbles.length, equals(3));
  //   expect(gameState.setsCompletedCount, equals(1));
  //   expect(gameState.currentBackgroundImage, equals(initialImageUrl)); // Same image
    
  //   // Test Set 2: Press 3 more words
  //   print('Testing Set 2...');
  //   await tapAllBubbles(tester, gameState);
    
  //   // Verify state after second set
  //   expect(gameState.bubbles.length, equals(3));
  //   expect(gameState.setsCompletedCount, equals(2));
  //   expect(gameState.currentBackgroundImage, equals(initialImageUrl)); // Still same image
    
  //   // Test Set 3: Press 3 more words - this should trigger new image
  //   print('Testing Set 3...');
  //   await tapAllBubbles(tester, gameState);
    
  //   // Verify state after third set - new image should load
  //   expect(gameState.bubbles.length, equals(3));
  //   expect(gameState.setsCompletedCount, equals(0)); // Reset after image change
  //   expect(gameState.wordsClickedCount, equals(0)); // Reset after image change
    
  //   // Verify new image was loaded
  //   final newImageUrl = gameState.currentBackgroundImage;
  //   expect(newImageUrl, isNotNull);
  //   expect(newImageUrl, isNot(equals(initialImageUrl)));
    
  //   print('Test completed successfully!');
  //   print('Initial image: $initialImageUrl');
  //   print('New image: $newImageUrl');
  // });
  
  testWidgets('Word pool management test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Get the game state
    final gameState = tester.state(find.byType(WordBubblesGame)) as dynamic;
    
    // Verify initial word pool
    expect(gameState.currentWords.length, equals(20));
    expect(teachableWords.length, greaterThan(80)); // Should have many words available
    
    // Verify bubbles are created from current words
    final bubbles = gameState.bubbles as List;
    final currentWords = gameState.currentWords as List;
    for (final bubble in bubbles) {
      expect(currentWords.any((w) => w.word == bubble.word.word), isTrue);
    }
    
    print('Word pool management test completed successfully!');
  });
  
  testWidgets('Game progression test - verify bubble count and behavior', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Get the game state
    final gameState = tester.state(find.byType(WordBubblesGame)) as dynamic;
    
    // Verify we start with 3 bubbles
    expect(gameState.bubbles.length, equals(3));
    
    // Tap one bubble
    final firstBubble = gameState.bubbles.first;
    
    await tapBubble(tester, firstBubble);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    
    // Verify the clicked bubble is marked as clicked and active. The game may
    // already have repopulated the next round after the speech completes, so
    // asserting a fixed list length here would race the refill timer.
    expect(firstBubble.isClicked, isTrue);
    expect(firstBubble.isActive, isTrue);
    expect(gameState.wordsClickedCount, equals(1));
    
    print('Game progression test completed successfully!');
  });
  

  testWidgets('Bubble movement and positioning test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Get the game state
    final gameState = tester.state(find.byType(WordBubblesGame)) as dynamic;
    
    // Verify bubbles have initial positions and movement
    final bubbles = gameState.bubbles as List;
    for (final bubble in bubbles) {
      expect(bubble.x, greaterThanOrEqualTo(0));
      expect(bubble.y, greaterThanOrEqualTo(0));
      expect(bubble.dx, isNot(equals(0))); // Should have movement
      expect(bubble.dy, isNot(equals(0))); // Should have movement
    }
    
    // Wait for some animation frames
    await tester.pump(const Duration(milliseconds: 100));
    
    // Verify bubbles are still within bounds and moving
    for (final bubble in bubbles) {
      expect(bubble.x, greaterThanOrEqualTo(0));
      expect(bubble.y, greaterThanOrEqualTo(0));
    }
    
    print('Bubble movement and positioning test completed successfully!');
  });

  testWidgets('Bubbles stay within the rendered game layer', (WidgetTester tester) async {
    await tester.pumpWidget(const WordBubblesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final gameState = tester.state(find.byType(WordBubblesGame)) as dynamic;
    final layerFinder = find.byType(AnimatedBubblesLayer);
    final layer = tester.widget<AnimatedBubblesLayer>(layerFinder);
    final layerSize = tester.getSize(layerFinder);
    final scaledInset = layer.bubbleSize * 0.05;
    final maxX = math.max(0.0, layerSize.width - layer.bubbleSize - scaledInset);
    final maxY = math.max(
      0.0,
      layerSize.height - layer.bubbleSize - layer.bottomPadding - scaledInset,
    );
    final minY = math.min(layer.topPadding, maxY);

    for (final bubble in gameState.bubbles as List) {
      expect(bubble.x, inInclusiveRange(0.0, maxX));
      expect(bubble.y, inInclusiveRange(minY, maxY));
    }
  });

  testWidgets('Bubble layer reserves controls and exposes keyboard actions',
      (WidgetTester tester) async {
    final bubbles = [
      WordBubble(
        word: teachableWords.first,
        x: 12,
        y: 90,
        dx: 0,
        dy: 0,
      ),
      WordBubble(
        word: teachableWords[1],
        x: 12,
        y: 90,
        dx: 0,
        dy: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 500,
          child: AnimatedBubblesLayer(
            bubbles: bubbles,
            onBubbleTap: (_) {},
            bubbleSize: 120,
            topPadding: 80,
            bottomPadding: 72,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final layerFinder = find.byType(AnimatedBubblesLayer);
    final layer = tester.widget<AnimatedBubblesLayer>(layerFinder);
    final layerSize = tester.getSize(layerFinder);
    final scaledInset = layer.bubbleSize * 0.05;
    final maxY = math.max(
      0.0,
      layerSize.height - layer.bubbleSize - layer.bottomPadding - scaledInset,
    );
    final minY = math.min(layer.topPadding, maxY);

    expect(bubbles.every((bubble) => bubble.y >= minY && bubble.y <= maxY), isTrue);
    expect(find.byType(FocusableActionDetector), findsNWidgets(2));
    expect(
      find.bySemanticsLabel('${teachableWords.first.word}. Tap to hear the word.'),
      findsOneWidget,
    );
  });
}
