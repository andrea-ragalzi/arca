# ARCA — Prototipo 0.3

Una breve missione completa: recupera il fusibile, alimenta il quadro e raggiungi l'uscita. Il raptor della 0.2 resta attivo e può essere abbattuto o aggirato. Munizioni illimitate; grafica e personaggio provvisori.

## Aprire sul PC di Andrea

1. Estrai l'archivio in una nuova cartella, accanto alla 0.2. Questo è un progetto completo: non serve copiare file nel progetto precedente.
2. Apri un terminale nella cartella `ARCA_Prototipo_0.3`.
3. Esegui `bash APRI_EDITOR_NVIDIA.sh` per aprire l'editor con la GPU NVIDIA, usando Godot 4.5.1 in `~/Applications/`.
4. Aspetta l'importazione iniziale, poi premi **F5**.

In alternativa importa `project.godot` dal Project Manager di Godot 4.5.1 Standard. Per giocare direttamente: `bash AVVIA_NVIDIA.sh`.

Scena principale: `res://arca/mission_room.tscn`. Aprila nell'editor per vedere e spostare fusibile, quadro e porta. F5 avvia sempre la missione completa; F6 avvia solo la scena aperta.

## Cosa fare

1. All'ingresso trovi il fusibile giallo sul supporto, poco avanti e a destra del giocatore. Avvicinati e premi **E**.
2. Raggiungi il quadro **02**, sul lato sinistro della stanza, nella metà occupata dal raptor. Premi **E** per installare il fusibile.
3. La porta **03**, in fondo al centro, si solleva. Attraversala fino alla striscia verde per completare la missione.

Gli obiettivi, lo stato del fusibile e il comando E sono visibili sullo schermo. Non serve leggere il pannello Output.

| Tasto | Azione |
|---|---|
| WASD | Movimento |
| Mouse | Camera |
| Mouse destro | Mira |
| Mouse sinistro mentre miri | Spara |
| Spazio | Salta |
| E | Raccogli / usa il quadro |
| R | Ricomincia e ripristina tutto |
| Esc | Pausa |
| F3 | Telemetria |

## File da esplorare per imparare

| File | Concetto |
|---|---|
| `arca/mission_room.gd` | Variabili di stato, inventario minimo e collegamento dei segnali |
| `arca/interactables/interaction_point.gd` | Area3D, vicinanza e controllo delle pareti |
| `arca/interactables/fuse_pickup.gd` | Segnale `collected`, rimozione dell'oggetto con `queue_free()` |
| `arca/interactables/power_panel.gd` | Controllare un requisito e annunciare l'alimentazione |
| `arca/interactables/sliding_door.gd` | Tween: movimento graduale della porta e della sua collisione |
| `arca/ui/hud.gd` | Aggiornare testi, inventario e schermata finale |

Le tre scene `.tscn` in `arca/interactables/` contengono nodi e geometria modificabili nell'Inspector. I segnali sono collegati in `_ready()` di `mission_room.gd`: non occorre collegarli manualmente.

Per leggere il percorso: parti da `_on_fuse_pickup_collected()`, poi `_on_panel_powered()`, infine `_on_exit_entered()`.

L'inventario è una variabile della missione, `has_fuse`. Dopo l'installazione diventa falsa e `power_restored` diventa vera. R ricarica la scena: niente salvataggi persistenti in questa versione.

## Novità rispetto alla 0.2

- Fusibile raccoglibile e quadro funzionante.
- Interazione E: distanza, pareti, un solo bersaglio per pressione.
- Obiettivi e stato inventario nel HUD; notifiche e due effetti audio originali.
- Porta animata con collisione, parete divisoria e zona di uscita.
- Fine missione, pausa e riavvio completo.
- Navigazione del raptor aggiornata agli ostacoli.
- Avvio dell'editor sulla NVIDIA già configurato.

La stanza della 0.2 rimane in `arca/raptor_room.tscn`; il collaudo originale in `arca/test_room.tscn`.

Licenze e crediti: `ATTRIBUTIONS.md`. Verifiche: `TEST_RESULTS_0.3.md`.
