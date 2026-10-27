# AURA

Flutter music application for iOS and Android. Source snapshot: 0.6.1.
Includes catalog search, artist discographies, related-artist discovery,
local playlists and favorites, synchronized lyrics when available,
background audio and customizable colors.

## Run

Install Flutter and the platform SDK, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

For Android: `flutter build apk --release`. The development signing setup
is for local testing; configure your own release signing before distribution.
For iOS: open `ios/Runner.xcworkspace`, configure your own development team
and a unique bundle identifier. This export uses `org.example.aura`.

Spotify import requires your own public Client ID and the registered callback
`org.example.aura.spotify://callback`. No Client Secret is needed. Keep the
native callback definitions and Dart configuration consistent if changing it.
Configure the metadata client's User-Agent contact URL for your own project.

## Privacy and scope

This is a source-only export with no Git history, device library, credentials,
Apple signing team, certificates, APKs, local tools, or development logs.
The application stores profile name, favorites and recent plays on-device.
Public music providers receive search terms and network requests.
Spotify tokens are used in memory for a single import.

The application has not undergone a comprehensive security audit.
Android's current build configuration uses development signing and default
OS backup behavior. Review privacy, signing and third-party service usage
before distributing it broadly.

The personalized Home currently under development is not included in this
stable 0.6.1 snapshot. Third-party reference mockups and private development
instructions have been excluded. Dependency notices, the Roboto font license
and the vendored just_audio MIT license are retained. Choose a license for
your own AURA code before presenting this as an open-source project.
