# Asset e provenienza

## Sfondo cosmico

File definitivo: `assets/images/cosmic-ribbon.png` (1024 × 1536).
Creato con il tool integrato image_gen e la skill imagegen; non con il fallback CLI. Il risultato è stato copiato nel progetto e ispezionato visivamente. L’app non dipende dalla copia nella cache del generatore.

Prompt finale, verbatim:

> Use case: stylized-concept. Asset type: portrait background illustration for AURA premium native music app, no UI. Primary request: a flowing sculptural liquid glass ribbon like an abstract cosmic wave, polished translucent chrome reflecting icy blue, silver, subtle peach and violet light, floating among delicate midnight blue nebula clouds and fine stars. The wave curves upward along the right half, with elegant negative dark space on upper left for app text. Overall dark navy / deep space background, a few soft glowing dust particles. Refined premium cinematic 3D rendering, realistic glass refraction, elegant rather than busy. Portrait 2:3 composition. No text, no logos, no phone frame, no typography, no interface, no watermark.

## Marchio

Originale disegnato in Canvas in `lib/core/design/aura_mark.dart`. File master `assets/icons/aura-icon.png`; tutte le dimensioni iOS e Android si rigenerano con `flutter test tool/generate_icons.dart`. Non viene usato il logo Spotify, YouTube o Apple Music come icona dell’app.

## Audio e testi

`assets/audio/orbita.wav` e `afterglow.wav`: basi sintetizzate originali, mono PCM 16 bit, 22050 Hz, 40 secondi. Sorgente riproducibile: `tool/generate_demo_audio.py`. Nessun campione o registrazione commerciale.

I versi dimostrativi di Orbita sono originali, inseriti in `lib/shared/models/music.dart`. La base è strumentale e non contiene una voce cantata. L’interfaccia lo dichiara. Per altri brani l’utente può importare un LRC di cui dispone legittimamente.

## Font e icone UI

Roboto distribuito con la licenza Apache in `assets/fonts/LICENSE.txt`, proveniente dai material_fonts del Flutter SDK installato. Material Icons distribuite tramite Flutter, con licenza nel SDK.

## Riferimento

`docs/reference/approved-mockup.png` è il mockup fornito dall’utente; viene conservato come riferimento progettuale e non usato come schermata dell’app. La UI è composta da widget Flutter reali.

## Immagini musicali 0.4

Foto e copertine sono recuperate a runtime da TheAudioDB e, come riserva, Deezer. Non vengono incluse nel repository come asset originali AURA. Cache locale per ridurre ricaricamenti e mantenere le immagini gia' viste. Le miniature del contenuto riprodotto restano una riserva. Crediti delle fonti nelle impostazioni.

Riferimento UI fornito dall'utente: `docs/reference/ui-purple-direction.png`, conservato per la direzione grafica; non usato come screenshot simulato del prodotto.

Documentazione: https://www.theaudiodb.com/free_music_api
