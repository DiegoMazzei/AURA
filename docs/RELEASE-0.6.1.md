# AURA 0.6.1 · Public Preview

La prima release scaricabile di AURA: Android e iOS, con una
vetrina aggiornata e schermate reali dell’app.

## In questa versione

- Esplorazione degli artisti simili e apertura delle relative discografie.
- Colori personalizzabili e preferenze persistenti.
- Brani, album, artisti seguiti e playlist personali.
- Coda contestuale all’album, riproduzione in background e controlli di sistema.
- Testi sincronizzati quando disponibili; importazione Spotify configurabile con un proprio Client ID.

## Download

| File | Destinazione |
| --- | --- |
| `AURA-0.6.1-Android.apk` | Android 7+, ARM64/ARMv7/x86_64, installazione manuale |
| `AURA-0.6.1-iOS-unsigned.ipa` | iOS 15+, dispositivi ARM64, da firmare prima dell’installazione |
| `AURA-0.6.1-Screenshots.zip` | Sei schermate reali dal simulatore iPhone |
| `SHA256SUMS.txt` | Verifica dell’integrità dei tre pacchetti |

**iOS:** il download non equivale all’installazione. L’IPA non include firma,
certificati o profili Apple personali. Occorre firmarla con un account e un
profilo compatibili; TestFlight non è ancora configurato.
[Guida Apple](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices).

**Android:** build di prova con firma di sviluppo, già utilizzata per i test.
Mantiene l’identificativo Android originale e i riferimenti dello sviluppatore
presenti nel binario; non contiene preferiti o cronologia del telefono.

## Provenienza e verifiche

- Codice applicativo dello snapshot ripulito 0.6.1, build 13.
- IPA ricompilata dai sorgenti ripuliti: bundle `org.example.aura`, build Xcode Release riuscita.
- APK stabile 0.6.1 già compilato dal progetto originale; i sorgenti esportati
  differiscono nei riferimenti personali, callback e configurazione di firma.
- Avvio sul simulatore, navigazione del catalogo e player verificati durante la cattura delle schermate.
- Analisi statica e 90 test superati sullo snapshot prima della pubblicazione;
  questa preparazione non cambia la logica dell’app.
- Archivi APK/IPA verificati e checksum SHA-256 allegati.

La disponibilità di metadati, immagini, riproduzione e testi dipende dai provider.
La Home personalizzata ancora in lavorazione e la Jam non sono incluse.
Non è una distribuzione App Store/Play Store né una build sottoposta a un audit completo.

La cronologia GitHub parte da uno snapshot ripulito; il changelog riepiloga
il percorso precedente senza importare la vecchia cronologia personale.
