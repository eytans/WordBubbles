# WordBubbles: Learn & Play

A Flutter educational game app that helps children learn words through interactive animated bubbles with text-to-speech functionality.

## Features

- **Animated Word Bubbles**: Interactive bubbles that bounce around the screen
- **Visual Modes**: Choose emoji bubbles or photo-style cards; words without a card safely fall back to emoji
- **Text-to-Speech**: Click on any bubble to hear the word pronounced
- **Random Background Images**: Beautiful packaged backgrounds that work offline
- **Progressive Learning**: New words are added as you complete sets
- **Background Music**: Optional local loop with mute, volume, lifecycle pause, and TTS ducking
- **Themed Frames**: The play frame changes theme as new backgrounds unlock
- **Visible Progress**: Shows set progress and bubbles found in the current set
- **100+ Educational Words**: Covering categories like animals, food, vehicles, emotions, shapes, and more
- **Cross-Platform**: Runs on Android and Web

## Original Implementation

This Flutter app is a rewrite of the original JavaScript/HTML WordBubbles game, maintaining all the core functionality while leveraging Flutter's powerful UI framework and native capabilities.

## How to Play

1. Watch the animated word bubbles bounce around the screen
2. Tap on any bubble to hear the word spoken aloud
3. Complete sets of words to unlock new backgrounds and vocabulary
4. Use the lower-left visual button to choose Emoji bubbles or Photo cards.
5. Adjust or mute background music from the lower-right control.
6. Learn through play with over 100 different words!

## Technical Features

- **Flutter Framework**: Built with Flutter for cross-platform compatibility
- **Text-to-Speech**: Uses `flutter_tts` package for speech synthesis
- **Local Images**: Packaged backgrounds keep the game usable offline
- **Photo Cards**: A small bundled AI-generated visual pack is available as an optional mode
- **Local Music**: Place the bundled track at `assets/audio/bgm.mp3`
- **Smooth Animations**: 60fps animations with bounded, non-overlapping bubbles
- **Responsive Design**: Adapts to different screen sizes

## Android release readiness

- Targets Android 16 (API 36), required for new Google Play app updates from August 31, 2026.
- Uses version `1.1.0+4` for the next Play testing release after the original `v1.0.0` tag.
- The release workflow produces a signed Android App Bundle (`.aab`) for Play Console and an APK for direct testing.
- GitHub Actions verifies an unsigned debug Android build on every main push; the signed release requires the repository keystore secrets.

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio (for Android development)
- Web browser (for web development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # For web
   flutter run -d web-server --web-port 8080
   
   # For Android
   flutter run -d android
   ```

## Project Structure

- `lib/main.dart` - Main application code with game logic
- `pubspec.yaml` - Dependencies and project configuration
- `web/` - Web-specific files
- `android/` - Android-specific files

## Dependencies

- `flutter_tts: ^4.2.0` - Text-to-speech functionality
- `audioplayers: ^6.1.0` - Local background music playback

## Educational Content

The app includes 100+ carefully selected words across various categories:

- **Animals**: cat, dog, bird, lion, elephant, etc.
- **Food**: apple, banana, pizza, ice cream, etc.
- **Vehicles**: car, train, airplane, bicycle, etc.
- **Emotions**: happy, sad, surprised, angry, etc.
- **Shapes & Colors**: circle, triangle, red square, blue circle, etc.
- **Nature**: cloud, rain, mountain, fire, etc.
- **Objects**: book, phone, computer, clock, etc.

## Contributing

Feel free to contribute by:
- Adding new word categories
- Improving animations
- Enhancing accessibility features
- Adding new languages

## License

This project is open source and available under the MIT License.
