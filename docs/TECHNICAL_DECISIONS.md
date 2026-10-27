# Decisioni tecniche

## 2026-10-27

1. Tutto lo sviluppo è stato spostato nella cartella Aura richiesta. La prima copia conservava percorsi assoluti in file generati Xcode: corretti verso la cartella attuale. I file generati restano esclusi da Git.
2. Flutter stable installato 3.47.8, Dart 3.13.7; dipendenze bloccate in pubspec.lock. Nessun aggiornamento globale forzato.
3. ChangeNotifier con dependency injection per la prima release: un controller centrale, motore e repository sostituibili, senza aggiungere un framework di stato prima di una necessità concreta.
4. just_audio per audio locale reale; audio_service stabile per controlli di sistema. L’add-on just_audio_background beta è stato valutato e rimosso a favore di un handler esplicito.
5. audio_session configurato come music; just_audio gestisce interruzioni e scollegamento cuffie con le opzioni predefinite. Da verificare sul dispositivo.
6. File Picker usa selezione esplicita dei file e copia in sandbox. Nessun accesso generale alla libreria musicale, microfono o foto richiesto.
7. Persistenza JSON atomica e serializzata, con backup dei dati corrotti, dietro interfaccia. Migrazione database pianificata per librerie grandi.
8. Spotify diretto richiede registrazione OAuth/PKCE e autorizzazione dell’utente. Per adesso è disponibile un’importazione locale JSON/CSV. Nessuna password o client secret nell’app.
9. Inizialmente il player YouTube usava esclusivamente IFrame. Dopo il requisito esplicito di navigazione e schermo bloccato, il percorso principale converte il risultato in una traccia del motore nativo. youtube_explode_dart risolve una sorgente audio MP4 transitoria; non vengono usati account, cookie, DRM o servizi di challenge. Il provider è sperimentale e non ufficiale. Il video incorporato rimane un fallback esplicito. Questa decisione sostituisce la precedente limitazione ai soli metadati.
10. Testi LRC forniti dall’utente, più versi originali dimostrativi su una base AURA. Sincronizzazione a righe, tap-to-seek e correzione ±5 secondi. Non è isolamento vocale.
11. Equalizzatore non implementato: l’interfaccia lo dichiara e non propone slider fittizi. Il volume applica realmente setVolume al motore.
12. Identificativo privato provvisorio: app.aura.personal per iOS/Android. Non implica disponibilità su store. Per iPhone verificare team e provisioning personale.
13. Il terminale ha limiti di sandbox su Swift Package Manager/CoreSimulator. La compilazione e l’avvio vengono provati da Xcode, senza disabilitare protezioni di sicurezza.

14. Prova dal vivo della ricerca: 20 risultati restituiti. Il metodo search della libreria falliva su una data relativa “Streamed”; l’adattatore usa searchContent e mappa soltanto i campi necessari, evitando il parser della data non utilizzata. Nessuna patch alla libreria globale.
15. Verifica in simulatore: ricerca di un brano reale, risultati con titolo/canale, selezione e caricamento del player IFrame interno. Il comportamento di riproduzione è riportato separatamente nell’avanzamento.

16. Preferiti e playlist YouTube precedenti vengono migrati nella libreria unica con identificatori yt:. I gruppi Artisti normalizzano spazi e maiuscole; gli Album includono l’artista nella chiave. Metadati corretti manualmente prevalgono sugli aggiornamenti del provider.
17. Namida è un riferimento di architettura Flutter (just_audio/audio_service), non una dipendenza né una base copiata. Licenza del progetto consultata: source available con restrizioni sul riuso e rebranding. Orbit-Music è una vetrina senza motore riutilizzabile. Nessun loro codice o asset è incluso in AURA.

18. Correzione 403: il manifest audio-only e una risposta 206 sui primi 1 KB non sono una prova di riproducibilità. Diagnosi con richieste successive e aperte riproduce il 403. Preferita una sorgente MP4 progressiva, consumata da just_audio come audio nativo; niente eccezioni ATS/HTTP né server loopback aggiunti. Aumenta il traffico rispetto all’audio-only. Test nativo ora include seek a 90 secondi e avanzamento successivo.

19. Il bundle iOS generico app.aura.personal non è disponibile per il Personal Team. Scelto org.example.aura per l’installazione privata e aggiornato l’origin del fallback video. Android conserva l’identificativo esistente.

20. Installazione privata riapribile dalla Home: schema condiviso AURA iPhone con LaunchAction Release e launcher senza debugger. Runner resta Debug per sviluppo. Una build Debug avviata da Xcode non costituisce un’installazione autonoma valida per la prova d’uso dell’utente.

21. Versione 0.2: interfaccia centrata su copertine e musica, senza particelle o etichette di sorgente nella ricerca principale. Materiali UIKit reali (`UIGlassEffect`, configurazione pulsanti `.glass()`) da iOS 26; nessuna imitazione dichiarata come nativa. Su altre piattaforme, controlli opachi standard.
22. MusicBrainz per identità e gruppi; Apple Search come riserva di metadati, senza preview audio o artwork promozionale Apple. Gli omonimi non vengono fusi soltanto in base al nome. Richieste serializzate e identificate, con backoff.
23. LRCLIB approvato dall’utente per testi sincronizzati; Genius resta consultazione esterna, senza scraping. I testi privi di tempi non abilitano karaoke fittizio.
24. Copertine online: conservata la miniatura della sorgente dopo l’associazione al catalogo; CAA può non avere una copertina per una release e non deve far sparire quella esistente.
25. Rimosse le tracce stock dalla produzione. Nessun miniplayer prima di una selezione reale; test espliciti per avvio vuoto e migrazione.
26. Route del player opaca: evita perdita di compositing Flutter quando si sovrappongono platform view native del dock e del player. SF Symbols mappati esplicitamente per testi, microfono, coda e playlist.

Fonti tecniche: [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_API), [Apple Search](https://performance-partners.apple.com/search-api), [LRCLIB](https://lrclib.net/docs), [Genius](https://docs.genius.com/), [UIKit UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect).

27. Versione 0.3: directory remota prima dell'ascolto. Search multi-entita' distingue artisti/album/brani; lookup per ID restituisce discografia e scalette. La discografia non deriva dalla raccolta locale.
28. Rimossi Esplora e contenuti ridondanti. Tre tab coerenti fra Flutter e UIKit: Ascolta, Cerca, Libreria.
29. Collaborazioni basate sui crediti del catalogo, senza dichiararle esaustive. Le uscite di altri artisti non entrano nella discografia soltanto perche' il nome cercato appare nel titolo.
30. Jam rinviata su istruzione esplicita dell'utente. Nessun backend implementato o pubblicato.

31. Direzione 0.4 derivata dal nuovo screenshot dell'utente: Home fotografica e accento viola. Le proposte editoriali non sono presentate come classifiche o preferiti personali.
32. Foto artista e copertine: TheAudioDB con riserva Deezer e miniature originali. Gli omonimi non sono selezionati solo per posizione nei risultati; confronto esatto dei nomi, ranking per pubblico nella riserva e nomi completi per album. URL e immagini hanno cache separate.
33. Seguire un artista e salvare un brano sono azioni distinte; ascoltare non salva automaticamente nessuno dei due. I vecchi recenti rimangono nella cronologia.

## 2026-10-27 · Materiale nativo e latenza immagini

Sostituiti i controlli custom del dock con UITabBarController e UITabAccessory. Evitate modifiche private alle sottoviste UIKit. Restano i comandi glass di sistema per gli altri pulsanti. Per le immagini: fallback del brano immediato da cache, fonti indipendenti con deduplicazione, immagini Deezer medium per ridurre il download e righe artista lazy. I limiti delle fonti e i controlli sulle corrispondenze rimangono attivi. Il tempo del primo caricamento dipende ancora da rete e fonti; non viene dichiarata una latenza garantita.

## 2026-10-27 · Ordine album e uscite annunciate

Corretto il passaggio scheda album -> player, che prima perdeva il contesto e manteneva la vecchia coda. Un nuovo avvio album disabilita shuffle; l’utente può riattivarlo. Successiva, precedente, fine automatica e controlli remoti condividono la stessa coda. Una registrazione assente conserva la propria posizione e produce un errore esplicito; nessuna sostituzione automatica con interpreti o versioni diversi. Upload alternativi sono provati solo con titolo, crediti e durata compatibili.

La ricerca prova crediti completi, artista principale/titolo e titolo/album. I crediti di un album collaborativo non sono assegnati a ogni traccia. La data completa delle uscite viene conservata e mostrata quando futura. Verifica pubblica del catalogo il 27 ottobre 2026: Seven Tears (6800830209), thélème / Jean-Christophe Groffe / Sting, releaseDate 2026-11-27; la presenza della scaletta non prova la disponibilità delle registrazioni. Le ricerche pubbliche dei primi titoli davano nessun risultato con tutti i crediti, oppure interpretazioni di altri artisti con query più generiche: queste non sono selezionate automaticamente.

## 2026-10-27 · Ernia BU! e risultati esclusi

Riprodotto con ricerca pubblica: Ernia BU! restituisce `_eSCaOsaboc`, titolo «Ernia - BU! (Visual)», autore Ernia, durata 205 secondi. Il matcher conservava il suffisso Visual e il filtro finale nascondeva la registrazione. Le etichette di presentazione Visual, Visual Video, Lyric Video, Video Lyrics e Testo tra parentesi vengono normalizzate; Live, Remix e altre versioni musicali rimangono significative.

Separati i criteri di scoperta da quelli di riproduzione automatica: i risultati non verificati rimangono disponibili nel selettore esplicito, con titolo e autore visibili. La coda automatica continua a usare solo corrispondenze verificate. Verificata dal vivo l’associazione del risultato Ernia dopo la correzione; non è una prova acustica della sorgente sul dispositivo.

## 2026-10-27 · Riproduzione diretta · 0.4.4

Su richiesta dell’utente, eliminato il selettore di registrazioni dal tap su un brano del catalogo. La stessa procedura automatica serve ricerca, scheda artista e album: il player si apre subito, il controller cerca e ordina le sorgenti e prova quelle compatibili senza domande. L’album conserva la scaletta; fuori da un album il brano avvia una coda singola.

Nessuna regola dipende dal nome dell’artista. Normalizzazione generale di etichette di presentazione, featuring, produzione, apostrofi, prefissi artista e canali VEVO/Topic. Il punteggio privilegia crediti e durata vicina, con margine limitato per intro/outro dei video. Live/remix/cover o brani estranei non vengono scelti come sostituti. Errori senza sorgenti compatibili restano nel player, senza rimandare a una scelta manuale.
