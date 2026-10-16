# Verifiche ARCA 0.3

Motore: Godot 4.5.1 Standard, versione ufficiale f62fdbde1. Verifiche eseguite in modalità headless; nessuna prova sulla GPU NVIDIA del PC dell'utente.

## Risultati

| Suite | Controlli | Fallimenti |
|---|---:|---:|
| Missione 0.3 | 28 | 0 |
| Raptor 0.2, regressione | 24 | 0 |
| Base TPS, regressione | 42 | 0 |
| Totale | 94 | 0 |

Sono stati controllati input E nel progetto, obiettivi e inventario sul HUD, distanza e pareti, pausa, emissione singola della raccolta, consumo del fusibile, requisito del quadro, animazione e collisione effettiva della porta, completamento all'uscita, blocco della ripresa dopo il successo, riavvio con R, ripristino dei materiali, impossibilità di raccogliere dopo la morte e inseguimento del raptor sulla navigazione della nuova stanza.

Le regressioni verificano anche proiettili reali, coperture, danni, morso evitabile, morte e riavvii ripetuti. Nessun errore o warning nei log delle tre suite finali.

Importazione da sorgenti e avvio della scena principale verificati con lo stesso motore. Sintassi dei tre launcher Bash verificata con `bash -n`.

La verifica grafica con una finestra OpenGL non è stata completata in questo ambiente. Il layout e il rendering vanno quindi confermati sul PC di Andrea. La grafica e il personaggio restano quelli provvisori della 0.2.

## Ripetere i test

Dopo l'importazione del progetto, dalla sua cartella, usa l'eseguibile Godot 4.5.1 al posto di `godot`:

```bash
godot --headless --fixed-fps 60 --path . -s res://arca/tests/mission_test.gd
godot --headless --fixed-fps 60 --path . -s res://arca/tests/raptor_test.gd
godot --headless --fixed-fps 60 --path . -s res://arca/tests/first_playable_test.gd
```

Ogni suite termina con codice 0 quando tutti i controlli passano.
