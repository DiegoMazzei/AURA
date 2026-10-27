# Trasferisci il catalogo · AURA 0.7.0

Apri **Impostazioni → Trasferisci il catalogo → Esporta catalogo**.
Salva lo ZIP in File/Drive o nella posizione scelta dal selettore di sistema.
Trasferiscilo sul nuovo telefono e scegli **Importa catalogo** nella stessa schermata.
Il formato è lo stesso su iPhone e Android.

Include preferiti, artisti seguiti, playlist, raccolte importate, cronologia e file
audio locali. Su una libreria nuova ripristina anche nome, tema e colore.
I brani online restano riferimenti e non vengono scaricati. Le immagini vengono
ricaricate dai provider. Non include token, credenziali o cache del vecchio telefono.

L’importazione aggiunge i contenuti senza cancellare quelli già presenti.
Importazioni ripetute dello stesso backup non duplicano brani e playlist.
In caso di identificativi in conflitto vengono rimappati i riferimenti del backup.
La riproduzione viene messa in pausa durante l’importazione e non riparte da sola.

Limite: 100 MB complessivi, inclusi audio e metadati; metadati massimo 20 MB.
Se un file locale manca, l’esportazione lo segnala anziché produrre un backup incompleto.
File non validi, versioni sconosciute, percorsi fuori dall’archivio e audio non integro
vengono rifiutati. Se il salvataggio fallisce, la libreria precedente viene mantenuta.
Il backup non è cifrato: contiene dati personali e va conservato privatamente.
Non allegarlo a issue o repository pubblici.
