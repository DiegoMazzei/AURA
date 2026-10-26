# Limitazioni conosciute

- Catalogo incluso: due basi strumentali originali di 40 secondi. Le atmosfere puntano a questo catalogo demo e sono etichettate come tali.
- Spotify: niente OAuth, token, sincronizzazione incrementale, artisti seguiti o importazione API diretta in questa release. JSON/CSV di playlist supportati; metadati e audio sono separati.
- YouTube: ricerca e risoluzione audio sperimentali tramite adattatore non ufficiale. Possono smettere di funzionare o essere limitati dal servizio. Prime 20 risposte per ricerca; niente paginazione esposta. Gli URL audio sono temporanei e non salvati nella libreria; niente download offline. Il fallback video IFrame richiede la schermata visibile. La prova iOS corrente fallisce nel caricamento della sorgente (HTTP 403 isolato con trasporto diagnostico). Background YouTube non funzionante/verificato in questo ambiente; vedere avanzamento.
- Testi: LRC a righe; niente timing a parole, fornitore remoto di testi o rimozione della voce. Le impostazioni di dimensione/offset karaoke durano nella schermata corrente.
- Equalizzatore: non disponibile; nessun controllo finge di cambiare il suono.
- Dynamic Island: nessuna Live Activity personalizzata. Metadati e comandi via media session configurati, da verificare su iPhone compatibile.
- Background, schermata di blocco, AirPlay, Bluetooth, interruzioni e haptics: da collaudare su dispositivo fisico. Nessuna promessa di supporto YouTube derivata dal player locale.
- Metadati: lettura di titolo/artista/album/durata dai file locali; tag musicali YouTube quando disponibili. I dati mancanti si possono modificare manualmente; nessun album inventato. Artwork YouTube remoto; per i file locali resta il fallback AURA, senza estrazione copertine embedded.
- Persistenza: adatta a una libreria personale contenuta, non a un catalogo di milioni di righe. Import metadati limitato a 20 MiB.
- Formati: selezione mp3/m4a/aac/wav/flac/ogg; il decoder effettivo dipende dal sistema. Un file non supportato genera un errore recuperabile.
- Android: SDK non presente al controllo; nessun APK prodotto o avvio Android verificato.
- Performance: nessuna misurazione 120 FPS, batteria o profilo su dispositivo reale effettuata.
- File importati: rimozione definitiva di file dalla libreria e pulizia spazio non ancora esposte. La rimozione da una playlist non cancella audio.
- Test iOS da terminale: limitazioni di sandbox SwiftPM/CoreSimulator; vedere log locali e avanzamento.
