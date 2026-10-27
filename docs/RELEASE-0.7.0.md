# AURA 0.7.0 · Public Preview

## Il primo ascolto lo scegli tu

- Nuova installazione neutra: ricerca e generi al posto di brani e artisti predefiniti.
- La Home suggerisce album e brani in base agli artisti seguiti, agli ascolti e ai preferiti.
- **Impostazioni → Trasferisci il catalogo**: esportazione/importazione ZIP su iPhone e Android.
- Backup di preferiti, artisti, playlist, raccolte, cronologia e file audio locali, fino a 100 MB.
- Importazione aggiuntiva: non cancella la libreria presente, evita duplicati e gestisce collisioni di identificativi.

I brani online restano riferimenti, non download. Foto e copertine vengono ricaricate.
Su una libreria nuova vengono ripristinati anche nome, tema e colore. Il backup contiene
dati personali e va salvato privatamente: non viene caricato automaticamente su GitHub.

## File

- `AURA-0.7.0-Android.apk`: Android 7+, APK di prova con firma di sviluppo.
- `AURA-0.7.0-iOS-unsigned.ipa`: iOS 15+, Release senza profili personali; richiede firma/provisioning prima dell’installazione. Non è un’installazione diretta da Safari e TestFlight non è configurato.
- `SHA256SUMS.txt`: integrità dei pacchetti.

Entrambi i pacchetti pubblici sono compilati dai sorgenti ripuliti. Non includono
password, token, cataloghi o cronologia personali. L’aggiornamento firmato
sull’iPhone di sviluppo mantiene separata la configurazione Apple personale.

## Verifiche

102 test superati e analisi senza segnalazioni. Coperti round-trip del catalogo,
file audio locali e loro verifica, importazione ripetuta, conflitti di identificativi,
file non validi, salvataggio fallito e prima apertura senza richieste di artisti.
Questi controlli non equivalgono a un audit di sicurezza completo.

[Backup e trasferimento](https://github.com/DiegoMazzei/AURA/blob/main/docs/CATALOGO_BACKUP.md) · [Installazione](https://github.com/DiegoMazzei/AURA/blob/main/docs/INSTALLAZIONE.md) · [Vetrina](https://diegomazzei.github.io/AURA/).
