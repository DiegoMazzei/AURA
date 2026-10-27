# Sicurezza

## Segnalare una vulnerabilità

Usa la sezione **Security → Report a vulnerability** del repository per
inviare una segnalazione privata. Se non disponibile, apri una issue priva
di dettagli sensibili chiedendo un canale privato prima di condividere il problema.
Non pubblicare credenziali, exploit con dati personali o file della libreria.

Indica versione, piattaforma, impatto e passaggi minimi per riprodurre il problema.
Non è garantito un tempo di risposta: AURA è un progetto personale in anteprima.

## Stato della versione 0.6.1

- Controlli di base sui sorgenti per credenziali comuni e metadati personali;
  non sostituiscono un audit completo.
- Preferenze e libreria in JSON nella directory privata dell’app, senza
  cifratura aggiuntiva a livello applicativo.
- Richieste di rete ai provider musicali e delle immagini.
- APK di prova con firma di sviluppo; IPA da firmare prima dell’installazione.

Non includere nei commit token, cookie, Client Secret, chiavi di firma,
profili di provisioning, database, file `.env` o log personali.
Vedi anche [Privacy](PRIVACY.md) e [Installazione](docs/INSTALLAZIONE.md).
