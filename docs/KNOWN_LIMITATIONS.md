# Limitazioni conosciute

- Nessun brano demo nella libreria di produzione; le basi originali rimangono fixture per i test.
- Spotify: importazione OAuth PKCE di playlist e preferiti implementata, ma richiede un Client ID registrato dall’utente. Importazione reale non verificata senza account configurato; nessuna sincronizzazione continua. JSON/CSV ancora supportati.
- YouTube: ricerca e risoluzione audio sperimentali tramite adattatore non ufficiale. Possono smettere di funzionare o essere limitati dal servizio. Prime 20 risposte per ricerca; niente paginazione esposta. Gli URL audio sono temporanei e non salvati nella libreria; niente download offline. Il fallback video IFrame richiede la schermata visibile. Il percorso MP4 progressivo supera il test di caricamento/riproduzione/seek sul simulatore; richiede più dati di una sorgente solo audio. L’utente ha confermato la riproduzione su iPhone e a schermo bloccato nella release precedente. Nessuna garanzia di disponibilità per ogni video.
- Testi: LRCLIB e importazione LRC a righe; niente timing a parole o rimozione della voce. Genius è un collegamento di consultazione esterno, non un importatore di testi integrali. Disponibilità e correttezza delle versioni dipendono dal catalogo; la ricerca automatica può essere integrata con una selezione manuale. Le impostazioni di dimensione/offset karaoke durano nella schermata corrente.
- Equalizzatore: cinque bande reali su iOS (MTAudioProcessingTap) e Android (AndroidEqualizer). DSP e passaggio di campioni AVPlayer verificati; la resa sonora resta da valutare durante l’ascolto sul dispositivo.
- Dynamic Island: nessuna Live Activity personalizzata. Metadati e comandi via media session configurati, da verificare su iPhone compatibile.
- Background e blocco: confermati dall’utente su iPhone per la release precedente. AirPlay, Bluetooth e interruzioni non hanno ancora una matrice di collaudo completa.
- Metadati: lettura di titolo/artista/album/durata dai file locali; tag musicali YouTube quando disponibili. I dati mancanti si possono modificare manualmente; nessun album inventato. Artwork YouTube remoto; per i file locali resta il fallback AURA, senza estrazione copertine embedded.
- Persistenza: adatta a una libreria personale contenuta, non a un catalogo di milioni di righe. Import metadati limitato a 20 MiB.
- Formati: selezione mp3/m4a/aac/wav/flac/ogg; il decoder effettivo dipende dal sistema. Un file non supportato genera un errore recuperabile.
- Android: SDK non presente al controllo; nessun APK prodotto o avvio Android verificato.
- Performance: nessuna misurazione 120 FPS, batteria o profilo su dispositivo reale effettuata.
- File importati: rimozione definitiva di file dalla libreria e pulizia spazio non ancora esposte. La rimozione da una playlist non cancella audio.
- Test iOS da terminale: limitazioni di sandbox SwiftPM/CoreSimulator; vedere log locali e avanzamento.

- Catalogazione: MusicBrainz e riserva Apple possono essere indisponibili o non avere una versione corretta. Gli abbinamenti automatici richiedono titolo/artista/durata compatibili e non sovrascrivono modifiche manuali. Identità provenienti da fornitori diversi rimangono distinte; è possibile scegliere un’associazione coerente dal menu del brano.
- Liquid Glass Apple disponibile soltanto su iOS 26+. Il materiale è UIKit; Android e iOS precedenti usano superfici standard.

- Ricerca a cataloghi: metadati Apple Search/Lookup per il territorio IT, massimo 100 risultati musicali nella ricerca e 200 uscite/scaletta per lookup. La scheda artista non dipende dagli ascolti. Brani in evidenza e collaborazioni derivano dai crediti restituiti, non sono un censimento completo di ogni partecipazione. Gli album con artista principale diverso vengono esclusi dalla discografia, salvo credito condiviso esplicito.
- Catalogo e registrazioni riproducibili sono separati: una corrispondenza univoca di titolo, artista e durata viene scelta automaticamente; il resolver prova automaticamente le registrazioni compatibili senza chiedere una scelta all’utente. Disponibilita' e versioni possono differire.
- I crediti degli ospiti privi di ID canonico sono conservati come nomi con prefisso `credit:`; non viene attribuito loro l'ID dell'artista principale. L'associazione MusicBrainz manuale rimane disponibile.
- Jam rinviata su richiesta dell'utente; nessun backend o account creato.

- Foto e copertine dipendono dalla copertura e disponibilita' di TheAudioDB/Deezer. Le immagini risolte sono tenute in cache sul dispositivo; in assenza di una copertina viene provata la miniatura originale. Non e' garantita una foto per ogni artista o un'immagine per ogni edizione.
- Artisti preferiti espliciti: i recenti non aggiungono artisti in Libreria. La Home distingue artisti seguiti da una selezione editoriale di scoperta. Non viene dichiarata una classifica in tempo reale.
