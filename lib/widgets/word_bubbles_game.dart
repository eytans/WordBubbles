import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/word_models.dart';
import '../data/teachable_words_data.dart';
import 'animated_bubbles_layer.dart';
import 'decorative_frame.dart';

enum BubbleVisualMode { emoji, photos }

class WordBubblesGame extends StatefulWidget {
  const WordBubblesGame({super.key});

  @override
  State<WordBubblesGame> createState() => _WordBubblesGameState();
}

class _WordBubblesGameState extends State<WordBubblesGame>
    with WidgetsBindingObserver {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  late final Future<void> _ttsInitialization;
  late final Future<void> _audioInitialization;

  List<WordBubble> bubbles = [];
  String? currentBackgroundImage;
  List<int>? _imageIds;
  int wordsClickedCount = 0;
  int setsCompletedCount = 0;
  List<TeachableWord> currentWords = [];
  final Random random = Random();
  Timer? _nextRoundTimer;
  bool _gameInitialized = false;
  int? _lastImageId;
  bool _audioAssetAvailable = false;
  bool _musicStarted = false;
  bool _musicMuted = false;
  bool _isTtsSpeaking = false;
  bool _resumeMusicOnForeground = false;
  double _musicVolume = 0.35;
  int _frameStyleIndex = 0;
  BubbleVisualMode _visualMode = BubbleVisualMode.emoji;
  
  static const int maxObjectsOnScreen = 3;
  static const double bubbleSize = 120.0;
  static const double animationSpeed = 2.0;
  static const String _musicAsset = 'audio/bgm.mp3';
  
  String? _currentImagePath;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ttsInitialization = _initializeTts();
    _audioInitialization = _initializeAudio();
    _loadImageIds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_gameInitialized) {
      _gameInitialized = true;
      _initializeGame();
    }
  }

  Future<void> _initializeTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      await flutterTts.setSpeechRate(isAndroid ? 0.5 : 1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
      await flutterTts.awaitSpeakCompletion(true);
    } catch (error) {
      debugPrint('Error initializing text-to-speech: $error');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await rootBundle.load('assets/$_musicAsset');
      _audioAssetAvailable = true;
      await _startBackgroundMusic();
    } catch (error) {
      debugPrint('Background music unavailable: $error');
    }
  }

  double get _effectiveMusicVolume {
    if (_musicMuted) return 0;
    if (_isTtsSpeaking) return _musicVolume * 0.2;
    return _musicVolume;
  }

  Future<void> _startBackgroundMusic() async {
    if (!_audioAssetAvailable || _musicMuted || _musicStarted || !mounted) {
      return;
    }

    try {
      await _bgmPlayer.play(
        AssetSource(_musicAsset),
        volume: _effectiveMusicVolume,
      );
      _musicStarted = true;
    } catch (error) {
      debugPrint('Background music could not start: $error');
    }
  }

  Future<void> _applyMusicVolume() async {
    if (!_audioAssetAvailable) return;

    try {
      if (!_musicStarted && !_musicMuted) {
        await _startBackgroundMusic();
      } else if (_musicStarted) {
        await _bgmPlayer.setVolume(_effectiveMusicVolume);
      }
    } catch (error) {
      debugPrint('Background music volume update failed: $error');
    }
  }

  Future<void> _toggleMusic() async {
    if (!mounted) return;

    setState(() {
      _musicMuted = !_musicMuted;
    });

    await _audioInitialization;
    if (!mounted) return;

    try {
      if (_musicMuted) {
        if (_musicStarted) await _bgmPlayer.pause();
      } else if (!_musicStarted) {
        await _startBackgroundMusic();
      } else {
        await _bgmPlayer.resume();
      }
      await _applyMusicVolume();
    } catch (error) {
      debugPrint('Background music toggle failed: $error');
    }
  }

  void _onMusicVolumeChanged(double volume) {
    setState(() {
      _musicVolume = volume;
      if (volume > 0) _musicMuted = false;
    });
    unawaited(_applyMusicVolume());
  }

  Future<void> _setTtsSpeaking(bool speaking) async {
    _isTtsSpeaking = speaking;
    if (!_musicStarted) return;

    try {
      await _bgmPlayer.setVolume(_effectiveMusicVolume);
    } catch (error) {
      debugPrint('Background music ducking failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _resumeMusicOnForeground = _musicStarted && !_musicMuted;
      unawaited(_pauseBackgroundMusic());
    } else if (state == AppLifecycleState.resumed &&
        _resumeMusicOnForeground) {
      _resumeMusicOnForeground = false;
      unawaited(_resumeBackgroundMusic());
    }
  }

  Future<void> _pauseBackgroundMusic() async {
    try {
      await _bgmPlayer.pause();
    } catch (error) {
      debugPrint('Background music pause failed: $error');
    }
  }

  Future<void> _resumeBackgroundMusic() async {
    try {
      await _bgmPlayer.resume();
      await _applyMusicVolume();
    } catch (error) {
      debugPrint('Background music resume failed: $error');
    }
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
      if (!mounted) return;
      setState(() {
        _imageIds = List<int>.from(config['imageIds']);
      });
      _loadNextImage();
    } catch (error) {
      debugPrint('Error loading image IDs: $error');
    }
  }

  void _loadNextImage() {
    if (_imageIds == null || _imageIds!.isEmpty || !mounted) return;

    final candidates = _imageIds!.where((imageId) => imageId != _lastImageId).toList();
    final imagePool = candidates.isEmpty ? _imageIds! : candidates;
    final imageId = imagePool[random.nextInt(imagePool.length)];
    _lastImageId = imageId;
    final newPath = 'assets/images/picsum/$imageId.jpg';

    setState(() {
      _currentImagePath = newPath;
      currentBackgroundImage = newPath;
      _frameStyleIndex = (_frameStyleIndex + 1) % FrameStyle.values.length;
    });
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
    final mediaQuery = MediaQuery.of(context);
    final gameArea = Size(
      max(0.0, mediaQuery.size.width - mediaQuery.padding.horizontal - 38),
      max(0.0, mediaQuery.size.height - mediaQuery.padding.vertical - 38),
    );
    final maxX = max(0.0, gameArea.width - bubbleSize);
    final maxY = max(0.0, gameArea.height - bubbleSize);
    final minY = min(100.0, maxY);
    
    return WordBubble(
      word: word,
      x: random.nextDouble() * maxX,
      y: minY + random.nextDouble() * (maxY - minY),
      dx: (random.nextDouble() - 0.5) * animationSpeed,
      dy: (random.nextDouble() - 0.5) * animationSpeed,
    );
  }

  Future<void> _speakWord(WordBubble bubble) async {
    if (bubble.isClicked) return;

    await Future.wait([_ttsInitialization, _audioInitialization]);
    if (!mounted || bubble.isClicked) return;

    setState(() {
      bubble.isClicked = true;
      bubble.isActive = true;
      bubble.dx = 0;
      bubble.dy = 0;
    });

    wordsClickedCount++;

    try {
      await _setTtsSpeaking(true);
      await flutterTts.speak(bubble.word.word);
    } catch (e) {
      debugPrint('Error speaking word: $e');
    } finally {
      await _setTtsSpeaking(false);
      _handleWordCleanup(bubble);
    }
  }

  void _handleWordCleanup(WordBubble bubble) {
    if (!mounted) return;

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
      _nextRoundTimer?.cancel();
      _nextRoundTimer = Timer(const Duration(milliseconds: 500), () {
        _nextRoundTimer = null;
        if (!mounted) return;
        _displayTeachableObjects();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nextRoundTimer?.cancel();
    unawaited(flutterTts.stop());
    unawaited(_bgmPlayer.stop());
    unawaited(_bgmPlayer.dispose());
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
          child: DecorativeFrame(
            style: FrameStyle.values[_frameStyleIndex % FrameStyle.values.length],
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
                    topPadding: 100,
                    showPhotoCards: _visualMode == BubbleVisualMode.photos,
                    accentColor: _frameAccentColor(
                      FrameStyle.values[_frameStyleIndex % FrameStyle.values.length],
                    ),
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
                  // Round progress stays visible while bubbles remain in the play area.
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Sets ${setsCompletedCount + 1}/3  •  '
                          '${wordsClickedCount % maxObjectsOnScreen}/$maxObjectsOnScreen found',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: PopupMenuButton<BubbleVisualMode>(
                        initialValue: _visualMode,
                        tooltip: 'Choose bubble visuals',
                        icon: Icon(
                          _visualMode == BubbleVisualMode.photos
                              ? Icons.photo_library
                              : Icons.emoji_emotions,
                          color: Colors.white,
                        ),
                        onSelected: (mode) {
                          setState(() {
                            _visualMode = mode;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: BubbleVisualMode.emoji,
                            child: Text('Emoji bubbles'),
                          ),
                          const PopupMenuItem(
                            value: BubbleVisualMode.photos,
                            child: Text('Photo cards'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: _musicMuted ? 'Turn music on' : 'Mute music',
                            color: Colors.white,
                            onPressed: _toggleMusic,
                            icon: Icon(
                              _musicMuted ? Icons.music_off : Icons.music_note,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Slider(
                              value: _musicVolume,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              label: 'Music volume ${(_musicVolume * 100).round()}%',
                              onChanged: _onMusicVolumeChanged,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            ),
          ),
        ),
      ),
    );
  }

  Color _frameAccentColor(FrameStyle style) {
    switch (style) {
      case FrameStyle.candy:
        return const Color(0xFFFF8A65);
      case FrameStyle.ocean:
        return const Color(0xFF0288D1);
      case FrameStyle.forest:
        return const Color(0xFF388E3C);
      case FrameStyle.galaxy:
        return const Color(0xFF512DA8);
    }
  }
}
