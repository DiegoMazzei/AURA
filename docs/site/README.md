# Vetrina AURA

Sito statico servito da GitHub Pages dalla cartella `/docs` del branch `main`.
Nessun framework o dipendenza JavaScript esterna, nessun cookie o analytics proprietario.
I browser e GitHub Pages gestiscono le normali richieste di rete.

## Anteprima

Dalla radice del repository:

```sh
python3 -m http.server 8765 --directory docs
```

Apri `http://localhost:8765`. Il documento è `docs/index.html`; stile e
comportamenti si trovano in `docs/site/`.

## Immagini

Le 16 varianti in `docs/showcase/themes/` sono catture reali della stessa
Home della versione 0.6.1, in due temi e otto colori. Non sono immagini ricolorate.
Il manifest indica l’origine. Le immagini dimostrative originali in PNG
rimangono nella galleria di prodotto; le versioni web sono JPEG ottimizzati.

Le cornici dei telefoni sono CSS illustrative. Le entrate usano IntersectionObserver;
il movimento allo scroll è sospeso con prefers-reduced-motion. Senza JavaScript
la pagina rimane leggibile e i link di download funzionano.

## Pubblicazione

GitHub Pages è configurato su main, cartella /docs. `.nojekyll` evita una
conversione dei contenuti. Dopo un push la pubblicazione è gestita da GitHub.
L’interfaccia iOS/Android non viene modificata da questo sito.
