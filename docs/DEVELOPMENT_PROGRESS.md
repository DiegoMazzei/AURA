# Avanzamento — 27 ottobre 2026

Cartella autorevole: `/path/to/Aura`.

## Completato e verificato

- Progetto Flutter iOS/Android, interfaccia cosmica, temi, mini player, player, coda, testi LRC e import locale.
- Preferiti unificati e persistenti, playlist, gruppi Artisti/Album e modifica informazioni; migrazione delle precedenti raccolte YouTube.
- `flutter analyze`: nessun problema. `flutter test`: 33 test superati, inclusi persistenza, migrazione preferiti, raggruppamenti, import, navigazione e golden.
- Ricerca YouTube reale: 20 risultati; risoluzione manifest: due sorgenti audio compatibili per video di prova. Questi controlli non provano da soli la riproduzione.
- Precedente prova nativa su simulatore: decodifica delle due basi locali, avanzamento, pausa, seek e persistenza file superati.

## Correzione del caricamento YouTube

- Diagnosi HTTP sul simulatore: gli stream adattivi audio-only accettano i primi byte, ma restituiscono 403 su richieste aperte e su alcune richieste successive. Il precedente controllo di soli 1024 byte era insufficiente.
- Selezione aggiornata: MP4 progressivo compatibile, scegliendo il bitrate complessivo più basso disponibile per contenere il traffico; il motore nativo riproduce la componente audio. In mancanza di una sorgente progressiva resta il tentativo MP4 audio-only. Non si usano WebView per il percorso principale, proxy esterni, credenziali o download offline.
- Test iOS reale sul simulatore: entrambe le prove di integrazione superate, inclusa sorgente YouTube, avanzamento, pausa e seek a 90 secondi con ulteriore avanzamento. Nessuna eccezione nel test finale. Il conteggio Xcode include anche tearDownAll.
- Prova nell’app: Senza Di Me (Gemitaiz) caricato nel player nativo, titolo/artista arricchiti; navigazione dal player alla libreria senza interrompere lo stato di riproduzione.
- Prova di blocco: la posizione avanza da circa 0:05 a 0:54 durante blocco/sblocco; questo non basta a confermare uscita audio e controlli OS. Il player di sistema non compare sul simulatore. L’utente riferisce che l’ascolto non funziona nel simulatore: verifica su iPhone reale ancora necessaria, nessuna dichiarazione di funzionamento completo.
- Test automatici: 33 superati; analisi senza problemi. SDK di verifica temporaneo in work/ per tenere le scritture di cache nel progetto senza cambiare l’installazione globale.

## Bloccato dall’ambiente o rimandato

- Android SDK assente: build APK non disponibile.
- Spotify OAuth, EQ reale, Live Activity personalizzata e verifiche Bluetooth/AirPlay non completati.
- Terminale limitato su SwiftPM/CoreSimulator: build e avvio iOS eseguiti dalla GUI Xcode.

Riferimenti esaminati: Namida e Orbit-Music. Nessun codice o asset copiato da questi progetti.

## Installazione sul telefono

- Xcode vede “iPhone di prova” ed è selezionato come destinazione; firma automatica e Personal Team già configurati.
- Tentativo di build su telefono bloccato da “Your session has expired. Please log in” e assenza del profilo di sviluppo per app.aura.personal. L’utente deve rinnovare la sessione Apple in Xcode Settings → Accounts; nessuna credenziale raccolta o modificata.
- Aggiunto controllo diagnostico di avvio della media session (AURA_MEDIA_SESSION_READY / FAILED) per la prova sul dispositivo. I comandi sulla schermata di blocco non sono ancora verificati.
- Retry dopo un errore del motore ricarica la sorgente, anziché riusare l’URL precedente. Regressione inclusa nei 33 test.

- Dopo il rinnovo dell’accesso Apple, app.aura.personal risulta non registrabile al team. Aggiornato il bundle iOS a org.example.aura e il relativo origin del fallback IFrame; Android invariato. Avviato nuovo tentativo di firma su “iPhone di prova”.

- Nuovo identificativo registrato: Xcode ora mostra un profilo gestito e un certificato Apple Development, senza l’errore di bundle occupato. Avvio su iPhone in corso; audio e controlli OS non ancora confermati dall’utente.

- Prima build Debug avviata su “iPhone di prova”; log AURA_MEDIA_SESSION_READY confermato. L’utente ha poi aperto l’icona dalla Home e ricevuto la limitazione JIT di Flutter Debug. Preparato schema condiviso “AURA iPhone”, Run in Release senza debugger, lasciando Runner in Debug. In corso sostituzione dell’app sullo stesso bundle (nessuna disinstallazione o cancellazione dati).

- Build Release completata e avviata su “iPhone di prova” con schema AURA iPhone, confermato da Xcode Running e AURA_MEDIA_SESSION_READY. Prodotto Release-iphoneos presente con il nuovo bundle e framework AOT; richiesta all’utente la prova di chiusura/riapertura dalla Home e ascolto reale in background/schermo bloccato. In attesa dell’esito, requisito audio non dichiarato completato.
