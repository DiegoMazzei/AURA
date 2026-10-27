# Importazione Spotify

Creare un’app nel pannello Spotify Developer e registrare esattamente il redirect:
`it.diegomazzei.aura.spotify://callback`

Inserire il Client ID pubblico in AURA → Impostazioni → Spotify. Non serve un
Client Secret. In modalità sviluppo Spotify richiede Premium al proprietario
ed eventuali utenti autorizzati nel pannello. Il browser gestisce l’accesso con
PKCE e i permessi di sola lettura per playlist e brani preferiti.

AURA importa metadati nella libreria; i token restano in memoria per la singola
importazione. Le playlist non accessibili vengono segnalate come saltate.
Senza un Client ID non è stato possibile verificare un’importazione reale.
