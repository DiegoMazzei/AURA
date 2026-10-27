# Contribuire ad AURA

AURA è un progetto personale di Diego Mazzei. Puoi proporre idee e segnalare
problemi tramite le issue del repository.

## Segnalazioni utili

Indica versione di AURA, modello del dispositivo, versione del sistema,
passaggi per riprodurre il problema e risultato atteso. Per il catalogo,
specifica artista, album e brano. Allega screenshot solo dopo aver rimosso
eventuali informazioni personali.

Non inserire password, token Spotify, cookie, chiavi o file della tua libreria.
Per problemi di sicurezza segui [SECURITY.md](SECURITY.md).

## Modifiche al codice

Prima di una modifica ampia, apri una proposta per concordarne l’obiettivo.
Mantieni le pull request concentrate su un solo problema e descrivi il
comportamento prima e dopo, con le verifiche effettuate.

```sh
flutter pub get
flutter analyze
flutter test
```

Le immagini in `docs/previews/` sono confronti visivi dei test; quelle in
`docs/showcase/` sono catture reali dal simulatore. Aggiornale solo quando
cambia l’interfaccia e descrivi come sono state ottenute.

Configura localmente account e firma; non includere mai le credenziali in una PR.
Non modificare licenze e attribuzioni delle dipendenze. La disponibilità pubblica
del codice non assegna automaticamente una licenza di redistribuzione.
