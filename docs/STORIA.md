# Dalla prima versione a oggi

Lo storico comprende tutti i **16 commit di sviluppo presenti nel repository
originale**, dal primo commit della 0.1.0 fino alla 0.6.1. Seguono i commit reali
della pubblicazione e della documentazione. Non sono state create date o versioni
per colmare eventuali intervalli precedenti al primo commit disponibile.

Autori, date, messaggi e successione sono conservati. Gli hash cambiano perché
i vecchi file sono stati ripuliti da percorsi personali, configurazioni di firma
e identificativi del dispositivo. I riferimenti grafici di terzi e le direttive
private non vengono pubblicati. I tag `history/` indicano snapshot dei sorgenti,
non pacchetti binari compilati né versioni nuovamente collaudate oggi.

## Cronologia verificabile

Tutti i commit originali risultano registrati il 27 ottobre 2026: sono le date
memorizzate in Git, non una ricostruzione delle date della conversazione.

| Versione registrata | Commit pubblico | Modifica |
| --- | --- | --- |
| 0.1.0+1 | [ad759c9](https://github.com/DiegoMazzei/AURA/commit/ad759c93066ba4460f482d8da77bff97d6d8834c) | Build AURA player and persistent unified music library |
| 0.1.0+1 | [71aed66](https://github.com/DiegoMazzei/AURA/commit/71aed66f96efc724e1861af444536eed2ab79124) | Restore legacy YouTube selection in unified native player |
| 0.1.0+1 | [6a218cf](https://github.com/DiegoMazzei/AURA/commit/6a218cf24f634f17957149be9fa15d7af58900c4) | Fix YouTube native source selection and prepare private iPhone release |
| 0.1.0+1 | [8583b45](https://github.com/DiegoMazzei/AURA/commit/8583b45dab1ea29d0759361cd814a98e4807c6d1) | Record signed release installation and pending iPhone audio verification |
| 0.2.0+2 | [e8ac82a](https://github.com/DiegoMazzei/AURA/commit/e8ac82a9c2146074ec5f43147f4d2b872622a656) | Refine AURA with native glass, catalog identities and synchronized lyrics |
| 0.3.0+3 | [89b9fd2](https://github.com/DiegoMazzei/AURA/commit/89b9fd25f338e4efb9ec8726a519d7480fdbfc48) | Add independent artist discography catalog and simplify music navigation |
| 0.4.0+4 | [718971a](https://github.com/DiegoMazzei/AURA/commit/718971aa9cbc0dfbded45977e786ef7488e32568) | Add purple photographic UI, artwork cache and explicit artist favorites |
| 0.4.1+5 | [53b2cd1](https://github.com/DiegoMazzei/AURA/commit/53b2cd1e1ee40399861d4301215ac0cb7d4403d3) | Use system iOS dock and remove artwork loading bottlenecks |
| 0.4.2+6 | [28e2c01](https://github.com/DiegoMazzei/AURA/commit/28e2c01dee160d3f0cceba6359a0602382da4017) | Preserve album tracklists in playback queue and explain upcoming releases |
| 0.4.3+7 | [6ef8399](https://github.com/DiegoMazzei/AURA/commit/6ef83994cc580c7c0093034e8847a79641002077) | Recognize Visual recordings and keep uncertain search results selectable |
| 0.4.3+7 | [c4bdab8](https://github.com/DiegoMazzei/AURA/commit/c4bdab89cd25b563df6dd3fb18427999b8c712bc) | Record verified iPhone installation of BU recording fix |
| 0.4.4+8 | [32760ba](https://github.com/DiegoMazzei/AURA/commit/32760bad794857acf72145c32d4a8517a1ab6c00) | Play catalog songs directly with general automatic recording ranking |
| 0.5.2+11 | [1b67b3b](https://github.com/DiegoMazzei/AURA/commit/1b67b3ba91c1c9b453fbf10b9a8f425fdf1b27b7) | Refine dashboard, group album editions and add personal music integrations |
| 0.6.0+12 | [17a251b](https://github.com/DiegoMazzei/AURA/commit/17a251bcbd944d38ad1696db9f2cf7f09964b61c) | Add persistent color personalization and build Android release APK |
| 0.6.1+13 | [80c66bf](https://github.com/DiegoMazzei/AURA/commit/80c66bf648dc287ab8570d4868c31f39253c9017) | Add interactive discovery of related artists |
| 0.6.1+13 | [ebc07cb](https://github.com/DiegoMazzei/AURA/commit/ebc07cb89f46d541cc12b190a7940861f261fdf5) | Organize Android installable package and project guide |

## Problemi, diagnosi e correzioni

| Problema | Diagnosi e soluzione adottata | Evidenza e limiti |
| --- | --- | --- |
| Errore 403 durante l’ascolto | I primi byte audio-only rispondevano, ma richieste successive fallivano. Preferenza per MP4 progressivo compatibile nel motore nativo. | Test con avanzamento, pausa e seek a 90 secondi; maggiore consumo di dati, nessuna garanzia per ogni registrazione. |
| Ascolto cambiando schermata o a schermo bloccato | Unificazione del player nativo con audio_service e media session. | Conferma d’uso su iPhone riportata nelle note; il solo avanzamento del cursore sul simulatore non prova l’uscita audio. |
| App iPhone non avviabile dall’icona | Una build Flutter Debug richiedeva l’avvio dagli strumenti di sviluppo. Preparato schema Release senza debugger. | Build AOT installata e avvio confermato; restano i vincoli del provisioning. |
| Artisti presenti solo dopo gli ascolti | Catalogo remoto distinto dalla libreria e dalla cronologia; schede con brani, album e collaborazioni. | Verifica del percorso Gemitaiz → Album → ELSEWHERE; completezza dei crediti dipendente dal provider. |
| Artisti aggiunti automaticamente in libreria | Separazione tra cronologia, brani preferiti e artisti seguiti esplicitamente. | Test di persistenza e indipendenza dall’ascolto. |
| Copertine e foto lente o mancanti | Cache, URL già risolti, richieste concorrenti per host e liste lazy. | Copertura delle immagini non universale; nessuna garanzia di tempi sulla rete dell’utente. |
| Successiva fuori dalla scaletta | Coda completa dell’album in ordine e risoluzione delle sorgenti al bisogno. | Regressioni su avvio da traccia intermedia, precedente/successiva e fine album. |
| Tracce del catalogo non riproducibili | Query alternative e confronto di titolo/artista/durata; rimozione dei falsi negativi per suffissi Visual. | Caso BU! di Ernia usato come regressione; generalizzazione a più artisti. Non tutte le pubblicazioni del catalogo hanno una sorgente compatibile. |
| Scelta manuale obbligatoria dopo il tap | Rimosso il selettore di registrazione dal flusso; ranking automatico dei candidati compatibili. | Test UI e verifiche di ricerca, distinti da un ascolto completo sul dispositivo. |
| Album duplicati | Raggruppamento per artista e titolo base; edizioni mantenute selezionabili. | Caso PER SOLDI E PER AMORE di Ernia, scalette da 12/13/14 tracce; non è una garanzia sull’intero catalogo. |
| Testi assenti o disallineati | LRCLIB con normalizzazione; timing incompatibile mostrato come testo semplice e importazione LRC alternativa. | Genius resta consultazione esterna; niente sincronizzazione parola per parola garantita. |
| Equalizzatore inizialmente assente | DSP iOS a cinque bande con MTAudioProcessingTap e AndroidEqualizer su Android. | Test DSP e campioni AVPlayer documentati; resa acustica da valutare sul dispositivo. |
| Collegamento Spotify | Implementazione PKCE senza Client Secret e procedura di configurazione. | Richiede Client ID proprio; importazione non verificata con un account reale nelle note di sviluppo. |
| Suggerimenti di artisti | Correlati Deezer con identificazione, deduplica e cache. | Verifica Gemitaiz → Ernia; omonimie e copertura restano limiti del catalogo. |

Le evidenze di questa tabella provengono dai documenti di sviluppo riportati
qui sotto e dai relativi commit. Descrivono le verifiche registrate allora:
non attestano che tutte le revisioni storiche compilino con gli SDK attuali.

## Documenti contemporanei

- [Diario di sviluppo e verifiche](history/DEVELOPMENT_PROGRESS.md)
- [Decisioni tecniche e alternative](history/TECHNICAL_DECISIONS.md)
- [Limiti conosciuti durante lo sviluppo](history/KNOWN_LIMITATIONS.md)
- [Istruzioni di installazione dell’epoca](history/INSTALLATION.md)

Per lo stato corrente usa [README](../README.md), [installazione attuale](INSTALLAZIONE.md)
e [note 0.6.1](RELEASE-0.6.1.md). Le note storiche possono contenere limiti poi superati.

## Versioni e tag

I numeri provengono dal `pubspec.yaml` dei commit. Non sono presenti commit
con versione 0.5.0 o 0.5.1: dopo 0.4.4 lo storico disponibile passa a 0.5.2.
Per la 0.1.0 il tag storico punta al primo commit, le successive correzioni
restano tutte consultabili nella cronologia.

- [history/v0.1.0](https://github.com/DiegoMazzei/AURA/tree/history/v0.1.0)
- [history/v0.2.0](https://github.com/DiegoMazzei/AURA/tree/history/v0.2.0)
- [history/v0.3.0](https://github.com/DiegoMazzei/AURA/tree/history/v0.3.0)
- [history/v0.4.0](https://github.com/DiegoMazzei/AURA/tree/history/v0.4.0)
- [history/v0.4.1](https://github.com/DiegoMazzei/AURA/tree/history/v0.4.1)
- [history/v0.4.2](https://github.com/DiegoMazzei/AURA/tree/history/v0.4.2)
- [history/v0.4.3](https://github.com/DiegoMazzei/AURA/tree/history/v0.4.3)
- [history/v0.4.4](https://github.com/DiegoMazzei/AURA/tree/history/v0.4.4)
- [history/v0.5.2](https://github.com/DiegoMazzei/AURA/tree/history/v0.5.2)
- [history/v0.6.0](https://github.com/DiegoMazzei/AURA/tree/history/v0.6.0)
