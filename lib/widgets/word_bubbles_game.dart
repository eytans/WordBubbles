import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';

import '../models/word_models.dart';
import '../data/teachable_words_data.dart';
import 'animated_bubbles_layer.dart';

class WordBubblesGame extends StatefulWidget {
  const WordBubblesGame({super.key});

  @override
  State<WordBubblesGame> createState() => _WordBubblesGameState();
}

class _WordBubblesGameState extends State<WordBubblesGame> {
  late FlutterTts flutterTts;
  late AudioPlayer _bgmPlayer;
  double _bgmVolume = 0.7;
  final double _duckedVolume = 0.2;
  bool _isDucked = false;
  
  List<WordBubble> bubbles = [];
  List<int>? _imageIds;
  int wordsClickedCount = 0;
  int setsCompletedCount = 0;
  List<TeachableWord> currentWords = [];
  final Random random = Random();
  
  static const int maxObjectsOnScreen = 3;
  static const double bubbleSize = 120.0;
  static const double animationSpeed = 2.0;
  
  // Add logging for image loading (visible in debug overlay)
  List<String> imageLoadLog = [];

  String? _currentImagePath;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeBgm();
    _loadImageIds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bubbles.isEmpty) {
      _initializeGame();
    }
  }

  void _initializeTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(Platform.isAndroid ? 0.5 : 2.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    // Ensure speak() awaits completion so we can restore music volume precisely
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _initializeBgm() async {
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(_bgmVolume);

    const String assetPath = 'assets/audio/bgm.mp3';
    try {
      // Check if asset exists. If it does, play it.
      await rootBundle.load(assetPath);
      await _bgmPlayer.play(const AssetSource('audio/bgm.mp3'));
    } catch (_) {
      // Fallback to a demo URL if no asset is present. Replace with your own track.
      // Note: Ensure this URL is HTTPS and permitted by platform policies.
      const String fallbackUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      try {
        await _bgmPlayer.play(UrlSource(fallbackUrl));
      } catch (e) {
        // If even the URL fails, silently ignore to avoid crashing the game.
      }
    }
  }

  Future<void> _duckBackgroundMusic() async {
    if (_isDucked) return;
    _isDucked = true;
    try {
      await _bgmPlayer.setVolume(_duckedVolume);
    } catch (_) {}
  }

  Future<void> _restoreBackgroundMusic() async {
    if (!_isDucked) return;
    _isDucked = false;
    try {
      await _bgmPlayer.setVolume(_bgmVolume);
    } catch (_) {}
  }

  void _initializeGame() {
    _initializeWordPool();
    _loadNextImage();
    _displayTeachableObjects();
  }

  void _initializeWordPool() {
    currentWords.clear();
    final shuffledWords = List<TeachableWord>.from(teachableWords)..shuffle(random);
    currentWords = shuffledWords.take(20).toList();
  }

  Future<void> _loadImageIds() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config/image_ids.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      setState(() {
        _imageIds = List<int>.from(config['imageIds']);
      });
      _loadNextImage();
    } catch (e) {
      print('Error loading image IDs: $e');
    }
  }

  void _loadNextImage() async {
    if (_imageIds == null || _imageIds!.isEmpty || _isLoadingImage) return;
    
    _isLoadingImage = true;
    final imageId = _imageIds![random.nextInt(_imageIds!.length)];
    final newPath = 'assets/images/picsum/$imageId.jpg';
    
    // Simply set the new image path - Flutter will handle caching and optimization
    if (mounted) {
      setState(() {
        _currentImagePath = newPath;
        _isLoadingImage = false;
      });
    }
  }

  void _displayTeachableObjects() {
    if (currentWords.isEmpty) {
      _initializeWordPool();
    }

    final wordsToDisplay = _getRandomWords(currentWords, maxObjectsOnScreen);
    
    setState(() {
      bubbles.clear();
      for (final word in wordsToDisplay) {
        bubbles.add(_createWordBubble(word));
      }
    });
  }

  List<TeachableWord> _getRandomWords(List<TeachableWord> words, int count) {
    final shuffled = List<TeachableWord>.from(words)..shuffle(random);
    return shuffled.take(count).toList();
  }

  WordBubble _createWordBubble(TeachableWord word) {
    final screenSize = MediaQuery.of(context).size;
    final maxX = (screenSize.width - bubbleSize).clamp(bubbleSize, double.infinity);
    final maxY = (screenSize.height - bubbleSize - 100).clamp(bubbleSize, double.infinity);
    
    return WordBubble(
      word: word,
      x: random.nextDouble() * maxX,
      y: random.nextDouble() * maxY,
      dx: (random.nextDouble() - 0.5) * animationSpeed,
      dy: (random.nextDouble() - 0.5) * animationSpeed,
    );
  }

  Future<void> _speakWord(WordBubble bubble) async {
    if (bubble.isClicked) return;

    setState(() {
      bubble.isClicked = true;
      bubble.isActive = true;
      bubble.dx = 0;
      bubble.dy = 0;
    });

    wordsClickedCount++;

    try {
      await _duckBackgroundMusic();
      await flutterTts.speak(bubble.word.word);
      await _restoreBackgroundMusic();
      _handleWordCleanup(bubble);
    } catch (e) {
      await _restoreBackgroundMusic();
      _handleWordCleanup(bubble);
    }
  }

  void _handleWordCleanup(WordBubble bubble) {
    setState(() {
      bubbles.remove(bubble);
    });

    if (bubbles.isEmpty) {
      setsCompletedCount++;
      if (setsCompletedCount >= 3) {
        _loadNextImage();
        setsCompletedCount = 0;
        wordsClickedCount = 0;

        // Add new words to the pool
        final availableNewWords = teachableWords
            .where((tw) => !currentWords.any((cw) => cw.word == tw.word))
            .toList();
        final shuffledAvailable = List<TeachableWord>.from(availableNewWords)
          ..shuffle(random);
        final newWordsToAdd = shuffledAvailable.take(6).toList();
        currentWords.addAll(newWordsToAdd);
      }
      
      // Display new objects after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _displayTeachableObjects();
      });
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    // Stop and release background music player
    try {
      _bgmPlayer.stop();
      _bgmPlayer.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
        ),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Static Background Image (not rebuilt on animation)
                  if (_currentImagePath != null)
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Image.asset(
                              _currentImagePath!,
                              key: ValueKey<String>(_currentImagePath!),
                              width: size.width,
                              height: size.height,
                              fit: constraints.maxWidth > size.width || constraints.maxHeight > size.height
                                  ? BoxFit.contain
                                  : BoxFit.cover,
                              alignment: Alignment.center,
                              cacheWidth: (size.width * 1.5).round(),
                              cacheHeight: (size.height * 1.5).round(),
                              filterQuality: FilterQuality.medium,
                            );
                          },
                        ),
                      ),
                    ),
                  
                  // Animated Bubbles Layer (isolated animation)
                  AnimatedBubblesLayer(
                    bubbles: bubbles,
                    onBubbleTap: _speakWord,
                    bubbleSize: bubbleSize,
                  ),
                  
                  // Title
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'WordBubbles: Learn & Play',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Debug Log Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (imageLoadLog.isNotEmpty)
                            ...imageLoadLog.take(3).map((log) => Text(
                              log,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
