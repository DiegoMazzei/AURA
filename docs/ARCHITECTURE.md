# Architettura AURA

Cartella autorevole: `/path/to/Aura`.
Riferimenti: `DEVELOPMENT_DIRECTIVES.md`, nuova direzione Apple Music richiesta dall’utente e `docs/DESIGN_SYSTEM.md`. Il mockup cosmico è conservato come riferimento storico.

## Struttura

- `app/`: bootstrap, temi, navigazione principale, controller iniettato.
- `core/design/`: token, superfici dei contenuti, bridge platform view per Liquid Glass UIKit.
- `core/audio/`: interfaccia AudioEngine, capacità dichiarate, adattatore just_audio e audio_service per i comandi di sistema.
- `core/storage/`: repository locale, importazione file, persistenza JSON atomica.
- `features/`: Home, ricerca/esplora, libreria/playlist, player/coda, testi sincronizzati, impostazioni e importazione metadati.
- `shared/models/`: brani, playlist, righe temporizzate e parser LRC.
- `test/`: logica, persistenza su filesystem, widget, immagini di riferimento.
- `integration_test/`: prova audio reale da eseguire su un target nativo.
- `tool/generate_icons.dart`: rendering del marchio disegnato in Canvas alle risoluzioni native.

## Stato e responsabilità

`AuraController` gestisce selezione, libreria, queue e comandi. AudioEngine è sostituibile nei test, così come LibraryStore. I tick di posizione aggiornano solo le superfici dipendenti dal tempo: barra progresso e testi. Il resto dell’interfaccia viene notificato ai cambiamenti effettivi di stato.

Le registrazioni audio sono distinte dai metadati importati: una riga Spotify non viene trattata come un file riproducibile. I brani importati da JSON/CSV appartengono a `ImportedCollection`, non alla coda audio locale.

`AuraAudioHandler` inoltra comandi di sistema allo stesso controller. Il player invia playback state e metadati ad audio_service. La configurazione nativa non equivale a una verifica di background/Bluetooth/Dynamic Island su un iPhone reale.

## Persistenza

Il repository salva in Documents/aura del sandbox dell’app, non nella cartella del progetto. I percorsi audio sono relativi al sandbox e sopravvivono alla rilocalizzazione del container iOS. Il JSON è versionato. Ogni scrittura usa un file temporaneo e rename; le scritture vengono serializzate. Un JSON non leggibile viene copiato in un backup prima di segnalare l’errore.

Questa prima versione usa un repository JSON per una libreria personale di piccole dimensioni. Una migrazione a Drift/SQLite sarà necessaria prima di grandi cataloghi o importazioni incrementali remote. L’interfaccia del repository separa questa scelta dalla UI.

## Catalogo e testi · 0.2

`MetadataCatalog` associa identificativi di registrazione, artista e release group. MusicBrainz è la fonte principale, Apple Search la riserva per soli metadati fattuali. Associazioni automatiche conservative, scelta esplicita per casi ambigui; i risultati non interrompono l’audio. Il raggruppamento usa gli identificativi persistenti e include gli artisti ospiti.

`LyricsProvider` separa LRCLIB dall’interfaccia. L’utente sceglie la versione da importare; testo normale e righe temporizzate restano distinti e persistenti. Genius viene aperto esternamente per consultazione.

`PublicMusicJsonClient` limita host, dimensione, timeout e frequenza; rispetta Retry-After e serializza richieste. Nessuna chiave o credenziale viene inclusa.

Avvio di produzione vuoto; i demo si abilitano soltanto con `includeDemoTracks: true` nelle fixture dei test. La migrazione rimuove i riferimenti ai demo dalla raccolta senza toccare i file personali.

## Directory remota indipendente dalla libreria - 0.3

`ArtistDirectory` separa risultati misti, artisti, uscite e scalette. `AppleArtistDirectory` usa Search/Lookup con cache limitata e client condiviso che limita la frequenza. Non utilizza audio preview o artwork promozionale Apple.

La directory e' iniettata in produzione e sostituibile nei test. Consultare il catalogo non inserisce canzoni nella libreria e non carica audio. Solo la selezione della registrazione crea la traccia riproducibile, conservando identita' e album scelti. Le risposte obsolete sono scartate; errori di catalogo non modificano il motore audio.

## Immagini e raccolta esplicita - 0.4

`ArtworkRepository` separa foto artista e copertine album. `MusicArtwork` interroga TheAudioDB, poi Deezer come riserva, richiede corrispondenze di nome e titolo e deduplica le richieste. Gli URL risolti sono conservati nel JSON, i file in cache su disco tramite flutter_cache_manager. Il client applica 2,1 secondi fra richieste AudioDB e 550 ms per Deezer, con Retry-After. Le immagini sono indipendenti dal caricamento audio.

`favoriteArtists` conserva ID, nome e genere separatamente dai preferiti dei brani. Non viene popolato dagli ascolti. `libraryTracks` include solo file personali, brani preferiti o playlist; la cronologia rimane separata. La vista Artisti di Libreria mostra soltanto artisti seguiti esplicitamente e apre la directory completa.

## Caricamento artwork · 0.4.1

Code di richieste separate per host, mantenendo intervalli e Retry-After. TheAudioDB e Deezer vengono consultati senza attendersi a vicenda; prevale il primo risultato con identità corrispondente. Le miniature dei brani già disponibili passano direttamente alla cache su disco senza ricerca preliminare. Discografia e brani nella scheda artista usano SliverList per istanziare solo le righe vicine al viewport. Nessuna modifica al motore audio.
