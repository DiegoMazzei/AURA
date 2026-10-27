# AURA

**Your Music. Your Universe.**

App musicale Flutter iOS/Android in sviluppo. Cartella di lavoro: `/path/to/Aura`.

## Prima versione

Home cosmica, vetro Flutter, particelle, navigazione flottante, ricerca musicale YouTube senza chiavi API e ricerca locale, Esplora, libreria, mini player espandibile e player completo. Temi chiaro/scuro/sistema.

Riproduzione reale di file locali e due basi strumentali originali demo. Play/pausa, seek, avanti/indietro, casuale, ripeti uno/tutti, volume, coda riordinabile. Preferiti, playlist modificabili e sessione salvati sul dispositivo.

Testi LRC importabili con sincronizzazione a righe e tap-to-seek. Importazione metadati di playlist da JSON/CSV, separati dall’audio; ricerca YouTube dentro AURA, scelta manuale del risultato e riproduzione nel player nativo. Preferiti e playlist unificati tra file locali e YouTube; viste Brani, Artisti, Album e Playlist, con modifica manuale dei metadati.

Spotify OAuth, equalizzazione e verifiche su iPhone reale non sono completati. La ricerca e la risoluzione audio YouTube usano adattatori non ufficiali, soggetti a limitazioni e cambiamenti del servizio. Il motore nativo e la media session sono configurati per il background; la verifica effettiva a schermo bloccato è ancora da completare. È disponibile un player IFrame come alternativa esplicita. Consultare le limitazioni prima di considerare finita una funzionalità.

## Sviluppo

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Aprire `ios/Runner.xcworkspace` in Xcode per la build iOS. Android richiede SDK/JDK configurati. Identificativi privati: iOS `org.example.aura`; Android `app.aura.personal`.

## Documentazione

- [Avanzamento](docs/DEVELOPMENT_PROGRESS.md)
- [Architettura](docs/ARCHITECTURE.md)
- [Design system](docs/DESIGN_SYSTEM.md)
- [Decisioni](docs/TECHNICAL_DECISIONS.md)
- [Limitazioni](docs/KNOWN_LIMITATIONS.md)
- [Installazione e test](docs/INSTALLATION.md)
- [Asset e prompt](docs/ASSETS.md)
- [Direttive fornite](DEVELOPMENT_DIRECTIVES.md)

Anteprime dei widget in `docs/previews`; riferimento approvato in `docs/reference/approved-mockup.png`.
