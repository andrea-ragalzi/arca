# ARCA 0.2 — Primo predatore

La stanza che hai collaudato ora contiene un raptor animato. Il giocatore resta il robot della TPS; il dinosauro è un modello low poly provvisorio. Questa versione verifica l'incontro, non la direzione artistica definitiva.

## Avvio sul tuo Pop!_OS

1. Estrai l'archivio in una cartella nuova, conservando la versione precedente.
2. Apri un terminale nella cartella che contiene `project.godot`.
3. Esegui:

```bash
bash AVVIA_NVIDIA.sh
```

Lo script cerca Godot 4.5.1 in `~/Applications/Godot_v4.5.1-stable_linux.x86_64`, il percorso che hai usato nel collaudo. Importa le risorse e avvia direttamente il gioco con le variabili NVIDIA. Non installa programmi e non modifica i driver.

Se hai spostato l'eseguibile, passa il percorso completo:

```bash
bash AVVIA_NVIDIA.sh /percorso/Godot_v4.5.1-stable_linux.x86_64
```

Puoi anche importare il nuovo `project.godot` dal gestore di Godot già avviato con NVIDIA e premere F5. La scena principale è `arca/raptor_room.tscn`. Il collaudo originale col robot resta disponibile aprendo `arca/test_room.tscn` e premendo F6.

## Cosa provare

Avvicinati al predatore nella stanza. Ti individua entro 10 metri quando ha una visuale libera; se gli spari si allerta anche da più lontano. Dopo una breve allerta ti insegue usando la navigazione della stanza. Le coperture sono ostacoli da aggirare.

Quando è abbastanza vicino si ferma brevemente e compare `!`: prepara il morso. Arretra durante questa fase. Il colpo infligge danno una sola volta e solo se resti a portata e in vista. Se lo uccidi durante la preparazione non arriva un morso postumo.

- Predatore: 6 HP; un proiettile valido infligge 1 HP.
- Giocatore: 100 HP; un morso infligge 20 HP.
- Munizioni illimitate per questo collaudo.
- Alla morte del giocatore il predatore smette di attaccare. R ricrea l'incontro da zero.

Controlli invariati: WASD, mouse, destro per mirare, sinistro per sparare, spazio, R per riavviare, Esc per pausa. F3 mostra gli stati per il collaudo.

## Asset e animazioni

Modello: **Velociraptor, Quaternius — Dinosaur Animated Pack, dicembre 2018**, CC0 1.0. Sorgente originale scaricato dalla pagina dell'autore su itch.io, licenza originale inclusa in `arca/assets/raptor/LICENSE_QUATERNIUS.txt`.

Le sei clip sono state enumerate dal file originale: Idle 2,5 s; Walk 2,4167 s; Run 0,5417 s; Attack 0,8333 s; Jump 1,125 s; Death 1,2917 s. Idle, Run, Attack e Death sono collegate al comportamento; Walk e Jump sono conservate ma non usate nell'IA di questo incremento. La preparazione del morso dura 0,45 s e la finestra di danno inizia a 0,24 s nella clip Attack.

Conversione FBX → scena Godot tramite l'importatore nativo → GLB tramite GLTFDocument, eseguita con Godot 4.5.1. Nessun Blender necessario per avviare il progetto. Il FBX originale è conservato in una sottocartella esclusa dall'importazione automatica. La scala del modello è stata adattata per questo test; non rappresenta una scelta paleontologica definitiva.

## Verifiche e limiti

24 controlli dell'incontro: animazioni, inseguimento, percorso intorno alle coperture, preparazione, danno singolo, schivata, muri, morte durante il morso, proiettili reali del controller originale e tre cicli morte/riavvio. La suite del robot mantiene i suoi 42 controlli.

La navmesh è precalcolata: non richiede un bake all'avvio. Cambiando le coperture va ricostruita con `arca/tools/bake_raptor_navigation.gd`. Per un solo nemico non sono stati aggiunti addon, behavior tree o sistemi di branco.

La grafica del dinosauro è provvisoria. Mancano ancora suoni dedicati al predatore, animazione specifica di reazione ai colpi, puzzle del fusibile, documento e percorso narrativo. Il corpo del dinosauro ha una collisione semplificata; testa e coda sono principalmente visive. Le prestazioni vanno ricontrollate sulla tua RTX 3050.

Il prossimo incremento utile è il piccolo percorso con locale tecnico e fusibile, usando questo incontro come ostacolo. Non sono stati aggiunti sistemi RPG o una seconda specie.
