# Privacy di AURA

Queste note descrivono la versione 0.7.0; non sono una certificazione di sicurezza.

## Dati sul dispositivo

AURA memorizza il nome scelto per il profilo, preferiti, artisti seguiti,
playlist, cronologia e impostazioni nella directory privata dell’app.
La libreria è salvata come JSON e non ha una cifratura aggiuntiva dell’app.
L’eventuale backup dipende dal sistema operativo e dalle sue impostazioni;
su Android questa versione usa il comportamento di backup predefinito.

I pacchetti distribuiti non includono la libreria personale dello sviluppatore.
Il repository e i commit riportano l’autore pubblico del progetto.

## Servizi esterni

Le funzioni di catalogo, immagini, testi e riproduzione richiedono connessioni
a provider esterni, fra cui YouTube, Apple, MusicBrainz/Cover Art Archive,
Deezer, TheAudioDB e LRCLIB. Le richieste possono includere termini di ricerca,
metadati del brano e il normale indirizzo IP della connessione. I provider
applicano le proprie condizioni e politiche di privacy.

Il collegamento a Genius apre il servizio esterno per consultare i testi.
AURA non include un servizio proprietario di analytics.

## Spotify

L’importazione richiede una configurazione Spotify Developer e un Client ID.
Usa OAuth con PKCE senza Client Secret. Il token viene usato in memoria
per l’importazione e non viene salvato nella libreria locale.
Non inserire password Spotify nell’app né nelle segnalazioni GitHub.

## Segnalazioni

Le issue pubbliche sono visibili a chiunque. Non allegare file della libreria,
credenziali, identificativi dei dispositivi o screenshot con dati personali.
Per vulnerabilità consulta [SECURITY.md](SECURITY.md).

## Backup del catalogo

Solo quando lo scegli, AURA esporta un file ZIP con i dati della libreria e i file
audio locali (massimo 100 MB). Non contiene token o credenziali e non viene
caricato automaticamente su GitHub o su un servizio AURA. Il backup non è
cifrato: salvalo in uno spazio privato. [Guida](docs/CATALOGO_BACKUP.md).
