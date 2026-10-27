# Design system · 0.2

Direzione richiesta: musica e copertine in primo piano, eleganza Apple Music con un accento pervinca discreto. La nuova direzione sostituisce il precedente mockup cosmico: eliminate particelle e sfondi illustrati dall’interfaccia principale.

## Materiali

Su iOS 26 e successivi, `AuraNativeUI` integra veri `UIGlassEffect` e `UIButton.Configuration.glass()` attraverso platform view Flutter. Il dock e i comandi appartengono allo strato funzionale flottante; le schede dei contenuti rimangono opache. Nessun BackdropFilter o shader viene presentato come Liquid Glass Apple. Su Android e iOS precedenti vengono usati controlli standard opachi.

Il player usa una route opaca: la precedente route trasparente causava la scomparsa degli strati Flutter tra le platform view native. La barra rimane sopra contenuti scorrevoli, così il materiale UIKit ha contenuto da rifrangere. Le impostazioni di accessibilità del materiale sono gestite da UIKit.

## Token

| Ruolo | Scuro | Chiaro |
|---|---|---|
| Fondo | #100B18 | #FAF7FF |
| Schede | #21162F | #EEE6F8 |
| Accento | #B486FF | #7435BC |
| Testo | ColorScheme.onSurface | ColorScheme.onSurface |

Carattere di sistema SF su iOS, Roboto sulle altre piattaforme; gerarchia 35/24/17/15/12, titoli con peso 600–700. Copertine con raggio 9–12, pannelli 14–18, dock 28. Controlli principali almeno 44 punti. Movimento ridotto rispettato nelle transizioni principali; nessuna decorazione animata continua.

## Contenuti

Nessun brano stock nella libreria di produzione. Avvio vuoto con invito alla ricerca, dock senza miniplayer finché manca una selezione. Le tracce demo rimangono solo come fixture esplicite nei test. Le copertine dei brani online mantengono la miniatura originale anche dopo l’associazione al catalogo; i metadati non devono sostituirle con un URL Cover Art Archive non verificato.

## Riferimenti forniti

Applicati i principi del file `apple-design` consegnato dall’utente e della guida Liquid Glass incollata in chat: gerarchia, contenuto, materiali sul solo strato funzionale, leggibilità e controlli riconoscibili. Il file allegato non include la cartella `references/`; non vengono attribuite citazioni a quei file mancanti. I token CSS sono un riferimento visivo per Flutter, non l’implementazione del materiale Apple.

Le anteprime in `docs/previews` sono render Flutter con fixture e controlli portabili. La verifica dei componenti UIKit avviene nel simulatore iOS; non va dedotta dai golden.

## Gerarchia 0.3

Tre destinazioni: Ascolta, Cerca, Libreria. Eliminati Esplora duplicato, grande billboard con slogan e schede ridondanti. Copertine recenti, preferiti e raccolta sono i soli contenuti di Ascolta; l'avvio vuoto invita alla ricerca.

Cerca: un campo e quattro filtri - Tutto, Brani, Artisti, Album. Artisti prioritari nella vista mista. Schede artista con titolo, genere e tre sezioni Brani/Album/Feat.; schede album con scaletta ordinata per disco e traccia. Miniplayer accessibile nei dettagli. I segnaposto del catalogo non rappresentano copertine reali; le copertine disponibili dei brani riprodotti rimangono visibili.

## Direzione 0.4 - riferimento fotografico viola

Il nuovo riferimento `docs/reference/ui-purple-direction.png` sostituisce la precedente direzione grafica: saluto compatto, filtri a pillola, dischi orizzontali da 154 punti con raggi 14, artisti fotografici circolari da 88 e gerarchia editoriale. Nessuna etichetta Trending senza una fonte di classifica.

Palette scura: fondo #100B18, schede #21162F, accento #B486FF, selezioni #8342CD. Variante chiara #FAF7FF e accento #7435BC. Restano materiali UIKit nel dock e controlli di sistema, con tinta viola. Tre destinazioni: Ascolta, Cerca, Libreria.

Schede artista: foto circolare 168 punti, azione Segui artista, sezioni Brani/Album/Feat. Schede album: copertina da 240 punti e scaletta. Foto e copertine compaiono anche nelle righe di ricerca e negli artisti salvati. Immagini mancanti non sono sostituite da foto inventate.
