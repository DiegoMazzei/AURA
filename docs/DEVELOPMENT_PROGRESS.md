# Avanzamento — 27 ottobre 2026

Cartella autorevole: `/path/to/Aura`.

## Completato e verificato

- Progetto Flutter iOS/Android, interfaccia cosmica, temi, mini player, player, coda, testi LRC e import locale.
- Preferiti unificati e persistenti, playlist, gruppi Artisti/Album e modifica informazioni; migrazione delle precedenti raccolte YouTube.
- `flutter analyze`: nessun problema. `flutter test`: 32 test superati, inclusi persistenza, migrazione preferiti, raggruppamenti, import, navigazione e golden.
- Ricerca YouTube reale: 20 risultati; risoluzione manifest: due sorgenti audio compatibili per video di prova. Questi controlli non provano da soli la riproduzione.
- Precedente prova nativa su simulatore: decodifica delle due basi locali, avanzamento, pausa, seek e persistenza file superati.

## Problema riprodotto sul simulatore

- Test reale del 27 ottobre: il file locale supera decode/play/seek/pause; il test YouTube fallisce nel caricamento nativo. Un trasporto diagnostico Dart ha isolato una risposta HTTP 403 dal server media nel simulatore, mentre il controllo CLI sul Mac risponde 206. Non è ancora determinato se la differenza dipenda dalla rete del simulatore o dal provider. Non attribuire il problema al decoder senza ulteriori prove.
- Anche user agent esplicito e trasporto loopback non risolvono il problema. Il trasporto sperimentale loopback è stato rimosso, senza eccezioni HTTP aggiunte alla configurazione di produzione.
- Il test di integrazione YouTube rimane come regressione reale, attualmente fallisce in questo ambiente. Il player mostra un errore recuperabile e permette il fallback video; questo fallback non soddisfa il requisito dello schermo bloccato.
- Navigazione durante la riproduzione, media session e schermo bloccato. Nessun collaudo su iPhone fisico completato.

## Bloccato dall’ambiente o rimandato

- Android SDK assente: build APK non disponibile.
- Spotify OAuth, EQ reale, Live Activity personalizzata e verifiche Bluetooth/AirPlay non completati.
- Terminale limitato su SwiftPM/CoreSimulator: build e avvio iOS eseguiti dalla GUI Xcode.

Riferimenti esaminati: Namida e Orbit-Music. Nessun codice o asset copiato da questi progetti.
