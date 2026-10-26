# Architettura AURA

Cartella autorevole: `/path/to/Aura`.
Riferimenti: `DEVELOPMENT_DIRECTIVES.md` e `docs/reference/approved-mockup.png`.

## Struttura

- `app/`: bootstrap, temi, navigazione principale, controller iniettato.
- `core/design/`: token, vetro Flutter, sfondi, particelle, marchio originale.
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
