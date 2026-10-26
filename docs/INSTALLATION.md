# Avvio e installazione privata

## Aprire il progetto

Cartella: `/path/to/Aura`.

```sh
cd /path/to/Aura
flutter pub get
flutter analyze
flutter test
```

## iOS

Aprire `ios/Runner.xcworkspace` con Xcode. Scheme Runner. Selezionare un simulatore installato e Run. Per un iPhone fisico: collegarlo, autorizzare il Mac, abilitare modalità sviluppatore se richiesta, scegliere il team personale in Signing & Capabilities e selezionare il dispositivo come destinazione. Account e conferme sul dispositivo spettano all’utente.

Per l’uso con Flutter CLI fuori dalle restrizioni della sessione:

```sh
flutter run -d <device-id>
```

Non è stato esportato un IPA. La distribuzione privata via account personale può richiedere rinnovi della firma; verificare lo stato del provisioning in Xcode.

I percorsi in `ios/Flutter/Generated.xcconfig`, `flutter_export_environment.sh` e `ephemeral/flutter_native_integration.env` devono puntare alla cartella attuale. Sono generati e non vanno committati. Dopo spostamenti del progetto rigenerare configurazione e pacchetti prima di compilare.

## Android

Installare/configurare Android SDK e JDK compatibili, poi:

```sh
flutter doctor -v
flutter doctor --android-licenses
flutter build apk --debug
```

Le licenze richiedono lettura/accettazione dell’utente. Il file atteso dopo una build riuscita è `build/app/outputs/flutter-apk/app-debug.apk`. Non è presente solo perché il progetto Android esiste.

## Prima prova dell’app

1. Dalla Home riprodurre Orbita, una base demo originale.
2. Aprire il mini player e provare pausa, avanzamento e cambio brano.
3. Toccare il cuore e ritrovare il brano in Libreria → Brani del cuore.
4. Creare una playlist e scegliere Brani nella sua schermata.
5. Importare propri file da Libreria → +.
6. Aprire Testi/Karaoke e importare un file LRC per un brano.
7. Cerca apre YouTube senza chiavi API. Cerca un brano, scegli il risultato e avvia il player. In alternativa incolla un link https YouTube.
8. Libreria → Brani del cuore raccoglie tutti i preferiti; Artisti e Album raggruppano i brani. Dal menu di un brano si possono correggere le informazioni.
9. Libreria → Importa le tue playlist accetta JSON o CSV; esempio in docs/examples.
10. Impostazioni permette sistema/chiaro/scuro.

## Verifiche

`flutter test` usa un motore audio finto per le interazioni, un filesystem temporaneo reale per la persistenza e immagini di riferimento. Il test `integration_test/native_audio_test.dart` usa il motore nativo reale:

```sh
flutter test integration_test/native_audio_test.dart -d <device-id>
```

Rigenerazione consapevole delle immagini dopo una modifica visuale:

```sh
flutter test test/visual_test.dart --update-goldens
flutter test tool/generate_icons.dart
```
