<div align="center">

![AURA — Your music. Your universe.](docs/showcase/aura-banner.svg)

**Un’esperienza musicale personale, tra scoperta e ascolto.**

[Scarica la release](https://github.com/DiegoMazzei/aura/releases/tag/v0.6.1) · [Installazione](docs/INSTALLAZIONE.md) · [Novità](CHANGELOG.md) · [Sicurezza](SECURITY.md)

![Versione](https://img.shields.io/badge/versione-0.6.1-b89be8?style=flat-square)
![Piattaforme](https://img.shields.io/badge/piattaforme-iOS%20%7C%20Android-35303f?style=flat-square)
![Stato](https://img.shields.io/badge/stato-private%20preview-35303f?style=flat-square)

</div>

## La tua musica, il tuo spazio

Cerca un brano, entra nella discografia di un artista e segui le connessioni con
altri musicisti. AURA riunisce catalogo, ascolto e libreria personale in
un’interfaccia dai colori personalizzabili.

| Scopri | Ascolta | Rendi tua AURA |
| :--- | :--- | :--- |
| Ricerca di brani, artisti e album | Riproduzione in background e controlli di sistema | Colori e profilo personale |
| Discografie ed edizioni raggruppate | Coda che mantiene l’ordine dell’album | Preferiti e playlist locali |
| Esplorazione degli artisti simili | Testi e karaoke quando sincronizzati | Artisti seguiti scelti da te |

## Download · 0.6.1

| Piattaforma | File | Come si usa |
| :--- | :--- | :--- |
| **Android 7+** | [Scarica APK](https://github.com/DiegoMazzei/aura/releases/download/v0.6.1/AURA-0.6.1-Android.apk) | Installazione manuale; build di prova con firma di sviluppo |
| **iOS** | [Scarica IPA da firmare](https://github.com/DiegoMazzei/aura/releases/download/v0.6.1/AURA-0.6.1-iOS-unsigned.ipa) | Richiede firma e provisioning; non è installabile direttamente dal download |
| **Integrità** | [SHA256](https://github.com/DiegoMazzei/aura/releases/download/v0.6.1/SHA256SUMS.txt) | Verifica i file scaricati |

Il repository e i download sono **privati**: serve un account GitHub autorizzato.
Per iOS non è ancora disponibile una distribuzione TestFlight.
[Leggi le istruzioni complete](docs/INSTALLAZIONE.md).

## Dentro l’interfaccia

Screenshot reali di AURA 0.6.1 in esecuzione sul simulatore iPhone, con
catalogo e immagini caricati dai provider. Nessuna ricostruzione grafica:
i render deterministici usati dai test rimangono separati in `docs/previews/`.

<table>
<tr><th>Home</th><th>Player</th><th>Artisti simili</th></tr>
<tr><td><img src="docs/showcase/home-ios.png" width="260" alt="Home scura AURA sul simulatore iPhone"/></td><td><img src="docs/showcase/player-ios.png" width="260" alt="Player reale con copertina"/></td><td><img src="docs/showcase/discovery-ios.png" width="260" alt="Artisti simili con fotografie"/></td></tr>
<tr><th>Scheda artista</th><th>Album e scaletta</th><th>Personalizzazione</th></tr>
<tr><td><img src="docs/showcase/artist-ios.png" width="260" alt="Scheda artista con brani e discografia"/></td><td><img src="docs/showcase/album-ios.png" width="260" alt="Scaletta dell’album"/></td><td><img src="docs/showcase/appearance-ios.png" width="260" alt="Impostazioni di tema e colore"/></td></tr>
</table>

Le immagini rappresentano una sessione dimostrativa, senza dati personali.
Le fotografie e le copertine appartengono ai rispettivi titolari.

## Cosa è disponibile

- Catalogo e ricerca: metadati di artisti e album distinti dalla cronologia degli ascolti.
- Preferiti: ascoltare un artista non lo aggiunge automaticamente agli artisti seguiti.
- Riproduzione: selezione automatica della registrazione e scaletta contestuale dell’album.
- Testi: sincronizzazione quando fornita da LRCLIB; consultazione esterna su Genius.
- Spotify: importazione predisposta con PKCE, richiede un proprio Client ID; nessun Client Secret.
- iOS: superfici native dove supportate e controlli di riproduzione di sistema.

Copertura del catalogo, immagini, testi e disponibilità della riproduzione
dipendono dai servizi esterni. La Home personalizzata in sviluppo e la Jam
non sono incluse in questa release. AURA non è affiliata ai servizi citati.

## Sviluppo

Richiede Flutter compatibile con Dart `^3.13.7`, Xcode per iOS e Android SDK/JDK per Android.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Android: `flutter build apk --release`. Configura una firma di produzione prima
di distribuire sul Play Store. iOS: apri `ios/Runner.xcworkspace`, scegli il tuo
Team e un bundle identifier univoco; lo snapshot usa `org.example.aura`.

Per Spotify registra il callback `org.example.aura.spotify://callback` e mantieni
coerenti configurazione nativa e Dart. Configura un contatto reale nel User-Agent
del client metadati. [Guida Spotify](docs/SPOTIFY_SETUP.md) · [Architettura](docs/ARCHITECTURE.md).

## Privacy e stato del progetto

Nome del profilo, preferiti e cronologia sono memorizzati localmente; i provider
ricevono le richieste di ricerca e rete. I token Spotify vengono usati in memoria
per l’importazione. I dati locali non hanno una cifratura aggiuntiva dell’app;
Android mantiene il comportamento di backup predefinito del sistema.

Questo repository nasce da una copia ripulita dei sorgenti: non include la
vecchia cronologia, librerie dei dispositivi, chiavi, certificati o profili Apple.
L’APK di prova già compilato conserva gli identificatori dello sviluppatore,
come spiegato nella guida. Non è stato eseguito un audit di sicurezza completo.

Il codice AURA non ha ancora una licenza di redistribuzione assegnata.
Le licenze dei componenti di terze parti, del font Roboto e della copia modificata
di `just_audio` sono conservate. [Sicurezza](SECURITY.md) · [Storia del progetto](CHANGELOG.md).
