# ARCA 0.1 — Risultati effettivi

Verifiche del 16 ottobre 2026, sul pacchetto compatto importato in una cartella inizialmente priva di cache Godot.

Engine eseguito: `4.5.1.stable.official.f62fdbde1`, Linux x86_64.

| Verifica | Risultato |
|---|---|
| Importazione pulita, Godot 4.5.1 | Completata; nessun errore di parsing, importazione o risorsa mancante nel log finale |
| Suite di integrazione con scene e fisica reali | **42 controlli superati, 0 fallimenti** |
| Movimento con il controller TPS e root motion | Verificato mediante azioni InputMap |
| Rotazione della camera con input mouse | Verificata |
| Pausa e ripresa tramite HUD | Verificate |
| Proiettile → robot | Un colpo sottrae esattamente 1 HP; il bersaglio può morire |
| Laser → giocatore | Un colpo effettivo sottrae 25 HP; nessun danno continuo a ogni frame |
| Allineamento effetto laser/collisione | Verificato dopo la correzione dell'asse del cannone |
| Pareti e coperture | Il proiettile viene fermato; origine del tiro corretta quando la canna supera un muro |
| Morte del nemico durante un attacco | Le chiamate di tiro successive non infliggono danni |
| Morte del giocatore | Arresta movimento e sparo, mostra il pannello e ignora ulteriori danni |
| Cinque cicli morte/riavvio | Salute e nemico ripristinati; un solo giocatore, una sola stanza e un solo HUD |
| Collisione con il perimetro | Il giocatore resta all'interno della stanza |
| Script di avvio Linux | Sintassi verificata con `bash -n`; il lancio grafico richiede un display locale |
| Cattura del gioco | Render reale 1280×720 con renderer Compatibility e Mesa llvmpipe; ispezionato visivamente |

Il log della suite consegnata è `arca/tests/last_run.txt`. La suite usa `--fixed-fps 60` per rendere riproducibile il tempo simulato: questo parametro **non misura né dimostra 60 FPS reali**.

## Limiti delle verifiche

- Non è stata eseguita la prova di cinque minuti sul PC dell'utente; GPU, FPS e latenza della sua macchina restano da misurare.
- La verifica visiva usa una GPU software in un display virtuale. Non rappresenta le prestazioni del PC di sviluppo e non costituisce un benchmark.
- Camera negli angoli, sensazione della mira e bilanciamento richiedono ancora una prova manuale con mouse. Collisioni e input automatici non sostituiscono questa valutazione.
- Non è stato verificato il gamepad né ascoltato l'audio su un impianto reale.
- Nella cattura sul display virtuale il driver segnala VSync non disponibile; alcune chiusure rapide possono segnalare risorse audio ancora in uso. La suite finale sul pacchetto pulito termina senza errori. Non è stato eseguito un test prolungato della memoria.

Il primo task del dossier è realizzato come incremento tecnico. Il criterio prestazionale sulla macchina reale resta aperto.

## Correzione ombre — 16 ottobre 2026

La prova dell'utente sulla RTX 3050 ha rilevato un errore durante il tiro del robot: `ShootLight` forzava `omni_shadow_mode = 0` (Dual Paraboloid), non supportato da Compatibility. La scena è stata corretta a `omni_shadow_mode = 1` (CubeMap). Il test grafico `arca/tests/shadows_test.gd` accende esplicitamente questa luce e fa esplodere un proiettile, coprendo gli effetti assenti dalla precedente cattura iniziale. I risultati della verifica grafica sono registrati nel lavoro di correzione; i test headless non verificano le shadow pass.

## Incremento 0.2 — primo predatore

24 controlli superati nel nuovo incontro: sei clip importate, navmesh, rilevamento, allerta, inseguimento, preparazione visibile, danno da morso singolo, schivata, occlusione delle coperture, aggiramento degli ostacoli, colpi bloccati dai muri, morte durante la preparazione, sparo originale contro il dinosauro e tre cicli morte/riavvio.

La suite del robot resta a 42 controlli superati. Il modello è stato renderizzato e ispezionato anche in OpenGL 3.3 Compatibility: ossa e animazioni visibili, scala del predatore adattata alla stanza. Il test grafico usa Mesa llvmpipe; non è una misura sulla RTX 3050. La compatibilità delle ombre del robot è già corretta nel pacchetto.

Log finali: `arca/tests/raptor_last_run.txt` e `arca/tests/last_run.txt`. La navmesh del livello ha 67 poligoni e tiene conto delle coperture statiche. La prova manuale del nuovo incontro sul PC dell'utente resta necessaria.
