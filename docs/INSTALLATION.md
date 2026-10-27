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

Aprire `ios/Runner.xcworkspace` con Xcode. Schema Runner per sviluppo Debug sul simulatore. Per installazione autonoma su iPhone usare lo schema **AURA iPhone**, che esegue Release senza debugger. Selezionare il dispositivo e Run. Per un iPhone fisico: collegarlo, autorizzare il Mac, abilitare modalità sviluppatore se richiesta, scegliere il team personale in Signing & Capabilities e selezionare il dispositivo come destinazione. Account e conferme sul dispositivo spettano all’utente.

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

### Prova su iPhone richiesta

In Xcode è disponibile la destinazione “iPhone di prova”. Se Signing & Capabilities segnala sessione scaduta, aggiornare l’account Apple in Xcode → Settings → Accounts, poi usare Try Again e Run. Autenticazione Apple e conferme sul telefono richiedono l’utente.

Dopo l’installazione: cercare un brano, confermare uscita audio, tornare a Home e Libreria, quindi bloccare lo schermo per almeno 30 secondi. Verificare ascolto continuo e comandi play/pausa dalla schermata di blocco. Il solo cursore che avanza non conferma questi requisiti.

Bundle iOS aggiornato per evitare il conflitto di registrazione: `org.example.aura`. Android mantiene `app.aura.personal`.

### Riapertura dall’icona dell’iPhone

Una build Flutter Debug su iPhone richiede l’avvio da Xcode/Flutter e può mostrare la schermata nera “In iOS 14+, debug mode Flutter apps can only be launched…” se aperta dall’icona. Lo schema condiviso `AURA iPhone` compila ed esegue Release senza debugger, così l’app può essere riaperta dalla Home. Lo schema `Runner` rimane Debug per sviluppo e test. Il certificato personale conserva i propri limiti di validità: Release non elimina la necessità della firma.
