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
