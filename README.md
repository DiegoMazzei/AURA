# AURA

**Your Music. Your Universe.**

App musicale Flutter iOS/Android in sviluppo. Cartella di lavoro: `/path/to/Aura`.

## Versione 0.4

Ricerca a cataloghi con filtri Tutto, Brani, Artisti e Album. Ogni artista apre brani, discografia e collaborazioni; ogni album apre la scaletta. I risultati non dipendono dagli ascolti o dalla libreria. Navigazione semplificata in Ascolta, Cerca e Libreria, senza sezioni duplicate. Preferiti e playlist persistenti. Home ispirata al nuovo riferimento: dischi in orizzontale, foto degli artisti, sfondo scuro e accento viola. Artisti preferiti espliciti e persistenti, separati dalla cronologia. Immagini da TheAudioDB/Deezer con cache su disco e miniature originali di riserva; vero Liquid Glass UIKit per dock e comandi su iOS 26+, controlli standard sulle altre piattaforme.

Riproduzione nativa con play/pausa, seek, coda, casuale e ripeti. L’utente ha confermato ascolto sull’iPhone anche cambiando schermata e a schermo bloccato nella release precedente. La ricerca utilizza YouTube senza selettori di sorgente nell’interfaccia principale; il servizio è indicato nelle informazioni e resta soggetto a cambiamenti.

Artisti e album associabili a MusicBrainz, con metadati Apple come riserva, identificativi persistenti e selezione manuale quando l’abbinamento è ambiguo. Testi sincronizzati da LRCLIB quando disponibili, importazione LRC/testo e collegamento esterno a Genius. Nessun testo non sincronizzato viene fatto passare per karaoke.

Spotify OAuth ed equalizzazione non sono attivi. Android non è ancora verificato su dispositivo. Consultare le limitazioni per stato e vincoli dei fornitori.

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
