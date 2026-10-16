# Documento del primo incremento 0.1

Per la versione corrente leggere `ARCA_0.2_LEGGIMI.md`. Il testo seguente conserva la documentazione della stanza robot.

# ARCA — Prototipo 0.1

Primo incremento del dossier operativo: una stanza 3D di collaudo TPS, eseguibile e modificabile. Data: 16 ottobre 2026.

## Avvio rapido

1. Scarica **Godot 4.5.1 Standard**, senza .NET: <https://godotengine.org/download/archive/4.5.1-stable/>.
2. Estrai tutto lo ZIP. In Godot scegli **Importa**, seleziona `project.godot` e attendi l'importazione delle risorse.
3. Premi **F6** sulla scena `arca/test_room.tscn`, oppure **F5** per avviare il progetto.

Su Linux puoi anche eseguire `bash AVVIA_LINUX.sh /percorso/Godot_v4.5.1-stable_linux.x86_64`. L'engine va scaricato separatamente. Lo ZIP contiene il sorgente Godot; non è una build standalone.

## Cosa puoi provare

- Movimento WASD o frecce, mouse per la camera mobile, spazio per saltare: controller e root motion originali TPS.
- Tasto destro per mirare, sinistro per sparare mentre miri. Una breve pressione del destro mantiene la mira; una pressione prolungata la disattiva al rilascio, come nella base.
- Un robot nemico con 5 HP, animazioni, inseguimento, preparazione e laser. Un colpo valido del giocatore sottrae 1 HP.
- Salute del giocatore: 100 HP. Il laser infligge 25 HP per colpo accettato, con protezione di 0,75 secondi fra danni.
- Coperture e pareti solide. I proiettili non attraversano i muri; la canna oltre una parete non genera il proiettile dall'altro lato.
- Morte, blocco degli input e pannello di riavvio. **R** ripristina l'intera stanza; **Esc** apre/chiude la pausa.
- **F3** mostra telemetria provvisoria; **F11** cambia modalità schermo.

Le munizioni sono illimitate per isolare i problemi del combattimento. Il test termina quando distruggi il robot; puoi continuare a muoverti o premere R per ripetere.

## Versioni e provenienza

- Engine congelato: `4.5.1.stable.official.f62fdbde1`.
- Base: <https://github.com/godotengine/tps-demo>, tag `4.5-90f2e38`.
- Commit upstream: `90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269`.
- Branch di lavoro locale: `arca/first-playable`.
- Renderer predefinito: **Compatibility / OpenGL**. La stanza non dipende da SDFGI, VoxelGI o dalla grande scena dimostrativa.
- Fisica: GodotPhysics3D, impostata esplicitamente al posto del vecchio valore Bullet presente nell'upstream.

Il pacchetto compatto conserva i percorsi originali delle dipendenze del controller e del robot. Esclude il grande livello dimostrativo, il menu multiplayer e i sorgenti Blender non usati dalla stanza. Il codice multiplayer già contenuto nel controller non è stato riscritto: il prototipo lo esegue in modalità offline.

## Collegamenti tecnici verificati

`InputMap` → `player/player_input.gd` (`PlayerInputSynchronizer`) → `player/player.gd` (`Player`). La camera espone la base di rotazione; l'AnimationTree produce root motion per movimento e strafe. Il rig rimane `PlayerModel/Robot_Skeleton/Skeleton3D`.

L'input proietta il mirino nella scena; il controller calcola il tiro da `GunBone/ShootFrom` verso quel punto. `player/bullet/bullet.gd` usa collisione cinematica e invoca `hit.rpc()` una sola volta. Il cooldown nativo dell'arma è di 0,4 secondi. ARCA aggiunge il solo hook `get_shoot_origin()` per la verifica della parete davanti alla canna.

`arca/player/arca_player.tscn` eredita il giocatore originale e aggiunge `HealthComponent`. Lo script ARCA estende quello TPS. Il laser del robot invoca `take_damage(25)` quando la sua collisione raggiunge il giocatore. `changed` aggiorna l'HUD; `died` arresta input, arma e attacchi pendenti. Il riavvio ricarica la scena: niente stato persistente fra tentativi.

## Modifiche necessarie all'upstream

1. `player/player.gd`: hook di origine del tiro; movimento, rig e animazioni conservati.
2. `player/player_input.gd`: il raycast esclude il RID del corpo del giocatore, anziché il nodo synchronizer.
3. `player/bullet/bullet.gd`: ritorno immediato dopo la scadenza del proiettile.
4. `enemies/red_robot/red_robot.gd` e relativa scena: danno esplicito, protezioni alla morte, asse del cannone e dell'effetto laser allineati, clipping/particelle coerenti, effetti contenuti nella stanza.
5. Timer dei rottami e scomparsa: legati ai nodi, così vengono eliminati al riavvio.
6. `player/model/player.glb`: rinominata soltanto la clip inutilizzata `Cannon_Charge` in `Charge_Single`, con sostituzione di 13 byte nel JSON interno. Il nome originale collideva con `Cannon_Charge-cycle` dopo l'importazione. Geometria, skin, rig e keyframe invariati.
7. `project.godot`: avvio diretto, risoluzione 1280×720, renderer leggero e azione R. Creato l'ambiente mancante `default_env.tres`.

La stanza e l'HUD sono scene `.tscn` modificabili nell'editor. Non sono immagini prerenderizzate. Nessun addon aggiunto e nessun asset Capcom incluso.

## Verifiche eseguite

Consultare `TEST_RESULTS.md` e `arca/tests/last_run.txt` per l'esito effettivo della distribuzione. La suite integra fisica, input, controller originale, proiettili, nemico, segnali e ricaricamento della scena.

Comandi riproducibili dalla cartella del progetto, con `godot` che indica l'eseguibile 4.5.1:

```bash
godot --headless --editor --import --path .
godot --headless --fixed-fps 60 --path . -s res://arca/tests/first_playable_test.gd
godot --path .
```

## Limiti e prossimo incremento

Questa è una stanza tecnica, con robot originali della TPS e geometrie provvisorie. Non rappresenta la grafica finale PS2/PS3 di ARCA e non include ancora Regina, Dylan, dinosauri, fusibile, documenti, inventario o salvataggi.

Resta da eseguire una prova manuale di cinque minuti sul PC di Andrea: registrare GPU, renderer, risoluzione, FPS e comportamento della camera negli angoli. Non è stata verificata una prestazione di 60 FPS sulla macchina dell'utente.

Il prossimo incremento è importare un solo predatore CC0, verificare le clip realmente presenti e collegarlo a navigazione, preparazione dell'attacco e danni. Il puzzle fusibile → quadro → porta viene dopo. La base della stanza va mantenuta come scena di regressione.

Licenze e crediti in `LICENSE.md`, `LICENSE_ARCA.md` e `ATTRIBUTIONS.md`.
