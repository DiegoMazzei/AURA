# Design system

Direzione: mockup approvato, interfaccia nativa Flutter, cosmica e trasparente.

- Midnight: #0A1120; chiaro: #F2F4FC.
- Accenti: #87B7FF blu, #AD96FF viola, #EC9BC5 rosa.
- Vetro: ClipRRect, BackdropFilter, gradiente traslucido, bordo sottile. È un materiale Flutter ispirato al vetro; non viene chiamato API Liquid Glass nativa Apple.
- Tipografia Roboto inclusa localmente, con licenza Apache nei font. Il layout segue scala del testo del sistema.
- Raggi: 12–18 copertine compatte; 24–32 pannelli/dock; 36 artwork grande.
- Mini player: transizione verticale e Hero per la copertina; cambio brano tramite AnimatedSwitcher.
- Navigazione: dock traslucido persistente, Home, Cerca, Esplora, Libreria.
- Movimento ridotto: particelle sospese, transizioni principali azzerate o ridotte. In background il ticker si ferma.
- Particelle: un CustomPainter, 36 punti deterministici, un controller, nessuna lista di widget animati per particella.
- Chiaro/scuro: sistema per default, override persistente nelle impostazioni.

Le copertine e le atmosfere sono originali dimostrativi AURA; non sono immagini o album di artisti commerciali. I colori assegnati guidano l’ambiente. Estrazione dei colori da copertine incorporate nei file non ancora implementata.

Anteprime renderizzate dai widget Flutter: `docs/previews/`. Non sono screenshot di un iPhone fisico. I test grafici disattivano il movimento e usano un orario fisso.
