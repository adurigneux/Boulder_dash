__includes ["IODA_2_3.nls"]

extensions [ioda]

breed [walls wall]
breed [magicwalls magicwall]
breed [heros hero]
breed [monsters monster]
breed [doors door]
breed [rocks rock]
breed [diamonds diamond]
breed [dirt]
breed [blast]
breed [explosives explosive]
breed [flags flag]
breed [cibles cible]

patches-own [ dijkstra-dist ]



globals       [ score nb-to-collect countdown directionOfHero headingRocksValueTemp levelNumber hasFlag hasTarget isTargetOpen? blockedIAgame waitingTimeBeforeEnd]
heros-own     [ moving? orders goals]
diamonds-own  [ moving?]
monsters-own  [ moving? right-handed? ]
rocks-own     [ moving? ]
walls-own     [ destructible? ]
magicwalls-own     [ destructible? ]
doors-own     [ open? ]
blast-own     [ strength diamond-maker? ]
explosives-own     [ time-to-explose ]


to setup
  clear-all
  init-world
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t(),"
  ioda:setup
  ioda:set-metric "Moore"
  reset-ticks
end

to go
  ioda:go
  tick

  if (blockedIAgame = true)
  [ set waitingTimeBeforeEnd waitingTimeBeforeEnd - 1
    if(waitingTimeBeforeEnd <= 0)
      [user-message "Niveau impossible !" ]
  ]
  ifelse(heros::isIAset?) [ set step-by-step? false ] [ set step-by-step? true ]
  ifelse (not any? heros)
    [ ifelse (countdown = 0) [ user-message "GAME OVER !" stop ] [ set countdown countdown - 1 ]]
    [ if (all? heros [any? doors-here with [open?]])
        [ user-message "CONGRATULATIONS !" next-level stop ]
    ]

end

to read-level [ filename ]
  if(not file-exists? filename)
  [user-message (word "Fichier " filename  " inexistant !")  stop ]
  file-open filename
  let s read-from-string file-read-line ; list with width and height
  resize-world 0 (first s - 1)  (1 - last s) 0
  let x 0 let y 0
  while [(y >= min-pycor) and (not file-at-end?)]
    [ set x 0
      set s file-read-line
      while [(x <= max-pxcor) and (x < length s)]
        [ ask patch x y [ create-agent (item x s) ]
          set x x + 1 ]
      set y y - 1 ]
  file-close
end


to next-level
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  ;clear-output
  reset-ticks
  set levelNumber levelNumber + 1
  init-global
  read-level (word "level" levelNumber ".txt")
  if ( file-exists? (word "level" levelNumber ".txt"))
  [set level (word "level" levelNumber)]

  set countdown 0
  set nb-to-collect count diamonds
  ask patches [set dijkstra-dist -1]
  ioda:setup
  ioda:set-metric "Moore"

end



to reset-level
  user-message "Abandon ? recommencez ,;)"
  set levelNumber levelNumber - 1
  next-level
end

to create-agent [ char ]
  ifelse (char = "X")
    [ sprout-walls 1 [ init-wall false ] ]
    [ ifelse (char = "x")
        [ sprout-walls 1 [ init-wall true ] ]
          [ ifelse (char = "W")
            [sprout-magicwalls 1 [init-magicwall ] ]
            [ ifelse (char = "O")
              [ sprout-doors 1 [ init-door ]]
              [ ifelse (char = "H")
                [ sprout-heros 1 [ init-hero ]]
                [ ifelse (char = "D")
                  [ sprout-diamonds 1 [ init-diamond ]]
                  [ ifelse (char = "R")
                    [ sprout-rocks 1 [ init-rock ]]
                    [ ifelse (char = "M")
                      [ sprout-monsters 1 [ init-monster ]]
                      [ ifelse (char = ".")
                        [ sprout-dirt 1 [ init-dirt ] ]
                        [ ifelse (char = "T")
                          [ sprout-cibles 1 [ init-cible] set hasTarget true]
                          [ ifelse (char = "F")
                            [ sprout-flags 1 [ init-flag] set hasFlag false]
                            [ ;;;;;; other agents ?
                            ]
                          ]
                        ]

                      ]
                    ]
                  ]
                ]
              ]
            ]
        ]
    ]
end

to init-world
  init-global
  read-level (word level ".txt")
  set levelNumber read-from-string substring level 5 6
  set countdown 0
  set nb-to-collect count diamonds
  ask patches [set dijkstra-dist -1]
end


to init-global
  set hasFlag false
  set hasTarget false
  set blockedIAgame false
  set waitingTimeBeforeEnd 50
  set isTargetOpen? false

  set-default-shape walls "tile brick"
  set-default-shape magicwalls "tile brick"
  set-default-shape heros "person"
  set-default-shape monsters "ghost"
  set-default-shape doors "door-open"
  set-default-shape rocks "rock"
  set-default-shape diamonds "diamond"
  set-default-shape dirt "dirt"
  set-default-shape blast "star"
  set-default-shape explosives "flower"
  set-default-shape flags "flag"
  set-default-shape cibles "target"
end
to init-flag
  set heading 0
  set color yellow - 1
end

to init-cible
  set color yellow - 1
  set heading 0
  set isTargetOpen? false
end

to init-hero
  ioda:init-agent
  set heading 0
  set color red
  set moving? false
  set orders []
  set goals []
end

to init-explosive
  ioda:init-agent
  set heading 0
  set time-to-explose limite-time-explosive ;;; depuis interface
  set color red
  set shape "flower"

end

to init-door
  ioda:init-agent
  set heading 0
  set color blue - 4
  set shape "tile brick"
  set open? false
end


to init-monster
  ioda:init-agent
  set heading 90 * random 4
  set color one-of (list blue yellow orange pink lime)
  set moving? true
  set right-handed? (random 2 = 0)
  if (right-handed?) [ set shape "butterfly" ]
end

to init-rock
  ioda:init-agent
  set color gray + 2
  set heading random 360
  set moving? false
end

to init-diamond
  ioda:init-agent
  set color cyan
  set heading 180
  set moving? false
  set nb-to-collect nb-to-collect + 1
end

to init-blast [ dm? ]
  ioda:init-agent
  set color orange
  set strength 3
  set diamond-maker? dm?
end

to init-dirt
  ioda:init-agent
  set color brown + 3
end

to init-wall [ d ]
  ioda:init-agent
  set destructible? d
  set heading 0
  set color blue - 4
end

to init-magicwall
  ioda:init-agent
  set destructible? true
  set heading 0
  set color blue
end



; primitives that are shared by several breeds

to-report default::nothing-below?
  report not any? turtles-on patch-at 0 -1
end

to-report default::nothing-ahead? [d]
  report not any? turtles-on patch-ahead d
end

to-report default::obstacle-ahead? [d]
  report any? turtles-on patch-ahead d
end

to-report default::moving?
  report moving?
end

to default::start-moving
  set moving? true
end

to default::stop-moving
  set moving? false
end

to default::move-down
  move-to patch-at 0 -1
end

to default::move-forward
  move-to patch-ahead 1
end

; doors-related primitives

to-report doors::open?
  report open?
end

to-report doors::closed?
  report not doors::open?
end

to-report doors::objectives-fulfilled?
  report nb-to-collect = 0 and ((hasTarget = true and isTargetOpen? = true ) or (hasTarget = false))
end

to doors::change-state
  set open? not open?
  ifelse open?
    [ set color yellow + 2
      set shape "door-open" ]
    [ set color blue - 4
      set shape "tile brick"
    ]
end


; diamonds-related primitives

to diamonds::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-at 0 -1)
end

to-report diamonds::nothing-below?
  report default::nothing-below?
end

to-report diamonds::moving?
  report default::moving?
end

to diamonds::start-moving
  default::start-moving
end

to diamonds::stop-moving
  default::stop-moving
end

to diamonds::move-down
  default::move-down
end

to diamonds::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = monsters) [ [right-handed?] of ioda:my-target ] [ true ]
  hatch-blast 1 [ init-blast dm? ]
end

to diamonds::die
  set nb-to-collect nb-to-collect - 1
  ioda:die
end

to diamonds::become-goal
  ask ioda:my-target
    [ set goals fput (list diamonds) goals
      ]
 end


; rocks-related primitives

to rocks::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-at 0 -1)
end

to-report rocks::nothing-below?
  report default::nothing-below?
end

to-report rocks::moving?
  report default::moving?
end

to-report rocks::direction-of-rock-is-ok?
  report (directionOfHero != 0)
end

to-report rocks::nothing-ahead?
  report default::nothing-ahead? 1
end

to rocks::set-direction-of-hero
  set heading directionOfHero
end

to-report rocks::nothing-right?
  set headingRocksValueTemp heading
  face patch-at 1 0
    ifelse rocks::nothing-ahead?
    [ report true ]
    [ set heading headingRocksValueTemp
      report false ]
end

to-report rocks::nothing-left?
  set headingRocksValueTemp heading
  face patch-at -1 0
    ifelse rocks::nothing-ahead?
    [ report true ]
    [ set heading headingRocksValueTemp
      report false ]
end

to-report rocks::nothing-down-left?
  set headingRocksValueTemp heading
  face patch-at -1 -1
    ifelse rocks::nothing-ahead?
    [ report true ]
    [ set heading headingRocksValueTemp
      report false ]
end

to-report rocks::nothing-down-right?
  set headingRocksValueTemp heading
  face patch-at 1 -1
    ifelse rocks::nothing-ahead?
    [ report true ]
    [ set heading headingRocksValueTemp
      report false ]
end

to rocks::roll-right
  face patch-at 1 0
  rocks::start-moving
  rocks::move-forward
end

to rocks::roll-left
  face patch-at -1 0
  rocks::start-moving
  rocks::move-forward
end

to rocks::move-forward
  default::move-forward
end

to rocks::start-moving
  default::start-moving
end

to rocks::stop-moving
  default::stop-moving
end

to rocks::move-down
  default::move-down
end


to rocks::create-one-diamond
  ask patch-here [ sprout-diamonds 1 [ init-diamond ] ]
end


to rocks::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = monsters) [ [right-handed?] of ioda:my-target ] [ true ]
  hatch-blast 1 [ init-blast dm? ]
end

to rocks::die
  ioda:die
end



; monsters-related primitives

to monsters::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to-report monsters::nothing-ahead?
  report default::nothing-ahead? 1
end

to-report monsters::moving?
  report moving?
end

to monsters::move-forward
  default::move-forward
end

to monsters::turn-right-or-left
  ifelse right-handed?
    [ right 90 ]
    [ left 90 ]
end

to monsters::die
  ioda:die
end

to monsters::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = heros) [ true ] [ right-handed? ]
  hatch-blast 1 [ init-blast dm? ]
end

; dirt-related primitives

to dirt::die
  ioda:die
end



;;;blast

to blast::create-diamonds
  ask neighbors [ sprout-diamonds 1 [ init-diamond ] ]
  ask patch-here [ sprout-diamonds 1 [ init-diamond ] ]
end

to blast::kill
  ask turtles-on neighbors
    [ ;output-show breed
      ;if (breed = walls) [output-show destructible?]

      ifelse ((breed = walls and destructible? = false) or breed = doors or breed = cibles or breed = flags)
      [ ;;je fais rien
        ]
      [ ioda:die ]
    ]
end

to-report blast::diamond-maker?
  report diamond-maker?
end

to blast::die
  ioda:die
end


; magicwall-related primitives
to magicwalls::die
  ask ioda:my-target [
    ioda:die
  ]
end


;;;;;;explosives

to-report explosives::explose?
  report time-to-explose <= 0
end

to explosives::update-timer
   set time-to-explose time-to-explose - 1
end

to explosives::die

  ; diams 1/3
  let valRand random 3
  let createDiams? false

  ;ifelse (valRand = 1)
  ;  [set createDiams? true]
  ;  [set createDiams? false]

  hatch-blast 1 [ init-blast createDiams? ]
  ioda:die
end




; hero-related primitives

to send-message [ value ]
  set orders lput value orders
end

to heros::filter-neighbors
  ioda:filter-neighbors-in-radius halo-of-hero
end

to-report heros::nothing-ahead?
  report (default::nothing-ahead? 1) or (any? (doors-on patch-ahead 1) with [ doors::open? ])
end

to-report heros::nothing-ahead-rocks?
  report default::nothing-ahead? 2
end


to-report heros::target-ahead?
  report ([patch-here] of ioda:my-target) = (patch-ahead 1)
end

to-report heros::moving?
  report moving?
end

to-report heros::needs-to-stop?
  report step-by-step?
end

to-report heros::message-received?
  report not empty? orders
end

to heros::drop-explosive
  ask patch-here [ sprout-explosives 1 [init-explosive] ]
end

to heros::handle-messages
  foreach orders
    [ let m ?
      ifelse (m = "STOP")
        [ set moving? false]
        [ ifelse (m = "EXPLOSIVE")
          [ heros::drop-explosive ]
          [set heading m set moving? true set directionOfHero m]
        ]

    ]
  set orders []
end


to heros::stop-moving
  set moving? false
end

to heros::start-moving
  set moving? true

end

to heros::die
  set countdown 10
  ioda:die
end

to heros::move-forward
  default::move-forward
end

to heros::create-blast
  hatch-blast 1 [ init-blast true ]
end

to heros::increase-score
  set score score + 1
end

to-report heros::own-flag?
  report hasFlag
end

to heros::receive-Flag
  set hasFlag true
end
;;;;;key

to flags::die
  ioda:die
end


to cibles::update-shape
    set shape "circle"
end


to-report cibles::die
   ioda:die
end

to cibles::check-flag
  if(hasFlag = true)
    [ set isTargetOpen? true
      cibles::update-shape ]
end


to-report heros::isIAset?
  report setIA?
end
;;;;;;ia method
to heros::interact-with-neighbor
 ; Select a random neighbor and interact with it
  heros::filter-neighbors
  let near one-of turtles with [breed = diamonds]
  if near != nobody [
    face near
    if [breed] of near = diamonds [ ;heros::move-forward
      ]
  ]
end

to heros::end-game
  set blockedIAgame true
end

to heros::continue-game
  set blockedIAgame false
end


to heros::choose-shortest-path
  let d [dijkstra-dist] of patch-here
  let n one-of (neighbors4 with [ is-path? d ]) with-min [dijkstra-dist]
  ;output-show n
  if(n != nobody) [face n]
end

to-report is-path? [ threshold ]
  report (dijkstra-dist >= 0) and (dijkstra-dist < threshold) and (not any? walls-here)
end


; dijkstra algorithm -> shortest path to specified agents (turtle procedure)
; the immediate? flag indicates if the path is computed from only accessible
; patches or with possible ways through doors in unknown state
to propagate-dist [ ag-or-pset ]
  ask patches with [ not any? walls-here ]
    [ set dijkstra-dist -1 set plabel "" ]
  let p ifelse-value (is-agentset? ag-or-pset) [ ag-or-pset ] [(patch-set [patch-here] of (ag-or-pset with [ ioda:alive? ]))]
  ask p
    [ set dijkstra-dist 0
      if show-dijkstra? [ set plabel 0 ]
    ]
  let s 0
  while [ any? p ]
    [ set s s + 1
      let pp patch-set ([neighbors4 with [ (not obstacle-here?) and ((dijkstra-dist < 0) or (dijkstra-dist > s)) ]] of p)
      ask pp
        [ set dijkstra-dist s
          if show-dijkstra?
          [ set plabel dijkstra-dist ]
        ]
      set p pp ]

    heros::repulsors
end

to-report obstacle-here?
  report any? walls-here or any? rocks-here
end

to heros::repulsors

  ; on ajoute une distance de 1 autour de tous les monstres sur un voisinages de 4
  let around-monsters [neighbors4] of monsters
  heros::increase-dijkstra-dist around-monsters 5

  let debut 0
  let fin 5
  let force 40

  ; Chute de diamants
  let fallingDiamonds diamonds with [not any? turtles-on patch-at 0 -1 or moving? = true]
  heros::increase-dijkstra-dist fallingDiamonds force

  ; Chutes de pierres
  let fallingRocks rocks with [not any? turtles-on patch-at 0 -1 or moving? = true]
  heros::increase-dijkstra-dist fallingRocks force


  while [debut <= fin]
  [
    let in-front-of-monsters [(patch-set patch-ahead debut)] of monsters
    heros::increase-dijkstra-dist in-front-of-monsters (fin - debut) * force


    let under-falling-rocks (patch-set )
    ask fallingRocks [set under-falling-rocks (patch-set under-falling-rocks heros::patch-under self )]
    heros::increase-dijkstra-dist under-falling-rocks (fin - debut) * force


    let under-falling-diamonds (patch-set )
    ask fallingDiamonds [set under-falling-diamonds (patch-set under-falling-diamonds heros::patch-under self)]
    heros::increase-dijkstra-dist under-falling-diamonds (fin - debut) * force


    set debut debut + 1
  ]

end

to heros::increase-dijkstra-dist [dangerous-patches value]
    ifelse (is-agentset? dangerous-patches)
    [    ask dangerous-patches with [dijkstra-dist >= 0] [set dijkstra-dist (dijkstra-dist + value) set plabel dijkstra-dist]]
    [
      foreach dangerous-patches
      [ask ? with [dijkstra-dist >= 0] [set dijkstra-dist (dijkstra-dist + value) set plabel dijkstra-dist]]
    ]
end


to-report heros::patch-under [agent]
  let dist 1
  let selectedPatch ( patch-set )
  loop
  [
    let pUnder [(patch-set patch-at 0 ( - dist))] of agent
    set selectedPatch (patch-set selectedPatch pUnder)
    if( not any? turtles-on pUnder ) [ report selectedPatch ]
    set dist dist + 1
  ]

end

to-report heros::path-to? [agentset]
  propagate-dist agentset
  let d [dijkstra-dist] of patch-here
  report any? neighbors4 with [ is-path? d ]
end


to-report heros::path-to-target?
  let goal ifelse-value (any? doors with [doors::open?])
      [(turtle-set doors)]
      [(turtle-set diamonds)]

  if(not any? goal)
   [  set goal ifelse-value (any? flags)
      [(turtle-set flags)]
      [(turtle-set cibles)]
   ]
   if(isTargetOpen? = true)
   [set goal (turtle-set doors)]
  ;output-show (turtle-set goal)
  report heros::path-to? (turtle-set goal)
end
@#$#@#$#@
GRAPHICS-WINDOW
482
10
727
221
-1
-1
36.0
1
10
1
1
1
0
0
0
1
0
4
-4
0
1
1
1
ticks
30.0

BUTTON
22
19
88
52
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
113
21
176
54
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
25
284
97
365
NIL
score
0
1
20

SLIDER
276
18
448
51
halo-of-hero
halo-of-hero
1
10
9
1
1
NIL
HORIZONTAL

BUTTON
187
425
250
458
up
ask heros [ send-message 0 ]
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

BUTTON
186
502
251
535
down
ask heros [ send-message 180 ]
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
186
463
250
496
STOP
ask heros [ send-message \"STOP\" ]
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

BUTTON
256
463
319
496
right
ask heros [ send-message 90 ]
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
118
463
181
496
left
ask heros [ send-message -90 ]
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

MONITOR
112
284
278
365
diamonds left
nb-to-collect
0
1
20

CHOOSER
278
63
416
108
level
level
"level0" "level1" "level2" "level3" "level4" "level5" "level6" "level7" "level8" "level9"
0

MONITOR
287
285
445
366
monsters left
count monsters
0
1
20

SWITCH
278
122
422
155
step-by-step?
step-by-step?
1
1
-1000

BUTTON
14
565
155
598
show primitives
setup\noutput-print ioda:primitives-to-write
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
18
617
461
743
11

INPUTBOX
25
84
180
144
limite-time-explosive
45
1
0
Number

BUTTON
30
389
147
422
Drop explosive
ask heros [ send-message \"EXPLOSIVE\" ]
NIL
1
T
OBSERVER
NIL
B
NIL
NIL
1

BUTTON
31
179
116
212
Abandon
reset-level
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
30
225
116
258
next level
next-level
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
272
202
375
235
setIA?
setIA?
0
1
-1000

SWITCH
272
240
407
273
show-dijkstra?
show-dijkstra?
0
1
-1000

@#$#@#$#@
## PROJET
Ce fichier est une implémentation basique du jeu "Boulder Dash", un jeu-vidéo datant de 1984, en utilisant l'extension IODA pour Netlogo.
## QUEL EST LE BUT?
Le principe du jeu consiste à ramasser un nombre défini de diamants pour ouvrir un passage vers le niveau suivant. Le personnage, surnommé Rockford, doit creuser la terre pour se frayer un chemin. Il devra faire attention à ne pas se faire écraser par un rocher ou un diamant mais également ne pas se faire toucher par les ennemis.
Certains niveaux n'ont pas de diamants. Le joueur doit alors les générer lui-même en faisant tomber un rocher/diamant sur un ennemi. Il devra préparer le terrain pour y arriver. Lorsqu'on élimine un ennemi de cette façon, celui-ci explose et fait apparaitre des diamants qui à leur tour, tomberont peut-être sur d'autres ennemis créant ainsi une réaction en chaîne. Le joueur peut également utiliser cette technique pour casser les murs et franchir des zones bloquées.
## RÈGLES DU JEU
Voici les règles qui régissent le jeu:
* le personnage principal creuse la terre en explorant la grotte
* le personnage principal peut pousser les pierres se trouvant à sa gauche et à sa droite
* les murs sont infranchissables, mais certains peuvent être destruits par une explosion
* certains murs sont magiques; ils sont perméables aux pierres et laissent tomber un diamant quand une de ces dernières le franchit
* une pierre peut tomber à sa gauche ou à sa droite si aucun obstacle ne se trouve sur son chemin
* si une pierre ou un diamant tombe sur le héros, celui-ci meurt
* les monstres mangent le héros s'ils le rencontrent
* quand une explosion se produit, elle se propage dans les cases adjacentes avec une force décroissante, tuant les monstres au passage et pouvant laisser derrière eux des diamants
* la porte de sortie apparaît quand le nombre minimal de diamants (présents dans le niveau) est atteint et que tous les drapeaux ont été plantés sur les cibles, si le niveau en possède.

## A PROPOS DES AGENTS
* Héros : L'automatisation du héros se réalise d'une manière proche de celle du modèle du jeu 'rescue the princess' du tutoriel IODA. Le héros à deux buts principaux dans l'ordre de priorité suivant, se diriger vers une porte ouverte et récupérer des diamants pour ouvrir la porte.
Pour pouvoir atteindre ses buts, une simple carte des distances est réalisée par l'algorithme de dijkstra.
Ensuite pour avoir un comportement un peu intelligent, les dangers comme les monstres, les explosions et les chutes de pierres ou de diamants agissent comme répulseurs et augmentent la valeur de la carte des distances de façon spécifique à l'agent. Un monstre a un effet répulseur sur les cases situées dans sa direction, ainsi qu'autour de lui et les objets qui tombent ont un effet répulseurs sur les cases situées sous eux.
* Explosives : Les bombes sont déposées par le héros sur la case en dessous de lui et explose apr!s un nombre de ticks donné et défini dans l'interface du jeu. Lors de l'explosion celle-ci detruit son voisinnage, tout en gardant les mêmes conditions qu'une explosions avec un monstres et une pierre, à savoir, destruction de l'environement destructible. L'explosion ne crée pas de diamants.
* Magicwalls : Les murs magiques sont destructibles et ils transforment les pierres qui tombent en diamants et inversement.
* Flags : Les drapeaux peuvent être pris par un héros lors de son passage sur la case, il doit être déposé sur une cible après avoir récolté tous les diamants pour finir le niveau
* Cibles : Les cibles sont utilisées pour déposer les drapeaux

## COMMENT UTILISER LE JEU?
Sélectionnez le niveau "0", et cliquez sur **`setup`** puis **`go`**.
Une fois un niveau franchi, le suivant est sélectionné automatiquement.

## INTERFACE DE JEU
Dans l'interface, l'utilisateur peut choisir plusieurs paramètres de jeu :
* Le bouton SetIA qui permet d'activer ou non l'intelligence artificielle du héros
* Le bouton show Dijkstra qui permet d'activer ou non l'affichage de la carte des distances selon l'algorithme de Dijkstra
* Le champ de saisie limit-time-explosive qui permet de déterminer la durée de vie des explosifs que le héros dépose avant que ceux-ci n'explosent
* Le bouton Drop explosive qui permet au héros de déposer des explosives sur la carte (raccourci clavier B)

## LES NIVEAUX
Il y a 10 niveaux en tout :
* Niveau 0 : Niveau de base pour tester les déplacements du héros
* Niveau 1 : Premier grand niveau avec monstres
* Niveau 2 : Même niveau que le 1 sans le sable
* Niveau 3 : Premier niveau équipé d'un mur magique qui transforme une pierre en diamant
* Niveau 4 : Premier niveau développé pour tester l'intelligence artificielle du héros
* Niveau 5 : Premier niveau équipé de nos agents cibles et drapeaux
* Niveau 6 : Niveau pour tester la récupération de diamants par l'intelligence artificielle
* Niveau 7 : Niveau où des pierres tuent des monstres dans le but de générer des diamants. L'IA doit également récupérer le drapeau pour le mettre sur la cible avant de finir le niveau.
* Niveau 8 : Niveau équivalent au niveau 7 avec rajout de deux nouveaux monstres
* Niveau 9 : Niveau où beaucoup de pierres tombent vers le héros et ajout de plusieurs monstres

## COMMENT CRÉER UN NOUVEAU NIVEAU?
Vous avez besoin d'un fichier texte présent dans le répertoire *level* sous la forme : *levelX.txt", où X est un entier suivant le nombre de niveaux déjà présents.
Vous pouvez créer les différents agents via ces caractères ASCII:

* H : héros du jeu
* M : monstre
* W : mur magique
* O : porte de sortie
* R : pierre
* . : sable
* D : diamant
* X : mur non-destructible
* x : mur destructible
* F : Drapeau (Flag)
* T : Cible pour drapeau

Les 2 premières lignes du fichier concerne la taille du niveau en longueur et en largeur (1ère ligne), et le nombre minimal de diamants à recueillir pour terminer celui-ci (2ème ligne).

## CONCERNANT L'APPROCHE IODA...

  * The **IODA methodology and simulation algorithms** (i.e. what is actually in use in this NetLogo extension):
Y. KUBERA, P. MATHIEU and S. PICAULT (2011), "IODA: an interaction-oriented approach for multi-agent based simulations", in: _Journal of Autonomous Agents and Multi-Agent Systems (JAAMAS)_, vol. 23 (3), p. 303-343, Springer DOI: 10.1007/s10458-010-9164-z.
  * The **key ideas** of the IODA methodology:
P. MATHIEU and S. PICAULT (2005), "Towards an interaction-based design of behaviors", in: M.-P. Gleizes (ed.), _Proceedings of the The Third European Workshop on Multi-Agent Systems (EUMAS'2005)_.
  * Do not forget to cite also **NetLogo** itself when you refer to the IODA NetLogo extension:
U. WILENSKY (1999), NetLogo. http://ccl.northwestern.edu/netlogo Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT NOTICE

A project by Antoine DURIGNEUX and Quentin WARNANT
All contents &copy; 2008-2015 Sébastien PICAULT and Philippe MATHIEU
Centre de Recherche en Informatique, Signal et Automatique de Lille (CRIStAL)
UMR CNRS 9189 -- Université de Lille (Sciences et Technologies)
Cité Scientifique, F-59655 Villeneuve d'Ascq Cedex, FRANCE.
Web Site: http://www.lifl.fr/SMAC/projects/ioda

![SMAC team](file:../../doc/images/small-smac.png) &nbsp;&nbsp;&nbsp;  ![CRIStAL](file:../../doc/images/small-cristal.png) &nbsp;&nbsp;&nbsp; ![CNRS](file:../../doc/images/small-cnrs.png) &nbsp;&nbsp;&nbsp;  ![Université de Lille](file:../../doc/images/small-UL1.png)

The IODA NetLogo extension is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

IODA NetLogo extension is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the IODA NetLogo extension. If not, see http://www.gnu.org/licenses.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

diamond
false
0
Polygon -13345367 true false 15 90 60 30 240 30 285 90 285 150 150 300 15 150
Polygon -11221820 false false 60 30 240 30 285 90 285 150 150 300 15 150 15 90
Line -11221820 false 15 150 285 150
Line -11221820 false 15 90 285 90
Line -11221820 false 120 30 90 90
Line -11221820 false 180 30 210 90
Line -11221820 false 150 30 150 90
Line -11221820 false 90 90 90 150
Line -11221820 false 150 90 150 150
Line -11221820 false 210 90 210 150
Line -11221820 false 90 150 150 300
Line -11221820 false 150 150 150 300
Line -11221820 false 210 150 150 300
Line -11221820 false 90 30 45 90
Line -11221820 false 210 30 255 90
Line -11221820 false 45 90 45 150
Line -11221820 false 255 90 255 150
Line -11221820 false 45 150 150 300
Line -11221820 false 255 150 150 300

dirt
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 114 91 65 71 15 57 66 81 180 135
Polygon -1 true false 179 209 243 239 280 246 196 206 129 184

door-open
false
15
Polygon -7500403 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 0 60 15 300
Polygon -6459832 true false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 60 30 105
Rectangle -1 true true 15 150 30 210
Circle -1 true true 75 120 30
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Circle -16777216 false false 75 120 30
Polygon -16777216 false false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 255 30 300
Rectangle -16777216 false false 15 255 30 300
Rectangle -16777216 false false 285 60 300 300

dot
false
0
Circle -7500403 true true 90 90 120

eyes
false
0
Circle -1 true false 62 75 57
Circle -1 true false 182 75 57
Circle -16777216 true false 79 93 20
Circle -16777216 true false 196 93 21

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghost
false
0
Circle -7500403 true true 61 30 179
Rectangle -7500403 true true 60 120 240 232
Polygon -7500403 true true 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -1 true false 81 78 56
Circle -16777216 true false 99 98 19
Circle -1 true false 155 80 56
Circle -16777216 true false 171 98 17

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pacman
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 105 -15 150 150 195 -15
Circle -16777216 true false 191 101 67

pacman open
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 270 -15 149 152 30 -15
Circle -16777216 true false 206 101 67

pellet
true
0
Circle -7500403 true true 105 105 92

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rock
true
1
Polygon -7500403 true false 45 75 15 135 15 165 30 195 30 225 60 240 75 240 120 270 165 285 210 270 240 240 255 195 270 165 285 150 285 120 270 75 240 45 210 45 165 30 165 15 120 0 90 30 75 60
Polygon -2674135 true true 90 45 120 15 165 30 195 15 240 60 270 75 285 120 270 165 270 210 225 255 180 270 120 285 75 225 15 195 30 135 30 90 45 60

rock 1
false
0
Circle -7500403 true true -2 118 94
Circle -7500403 true true 176 176 127
Circle -7500403 true true 171 21 108
Circle -7500403 true true 28 43 95
Circle -7500403 true true 173 68 134
Circle -7500403 true true 53 173 134
Circle -7500403 true true 78 48 175

scared
false
0
Circle -13345367 true false 61 30 179
Rectangle -13345367 true false 60 120 240 232
Polygon -13345367 true false 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -16777216 true false 81 78 56
Circle -16777216 true false 155 80 56
Line -16777216 false 137 193 102 166
Line -16777216 false 103 166 75 194
Line -16777216 false 138 193 171 165
Line -16777216 false 172 166 198 192

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

sss
true
0
Rectangle -7500403 true true 60 45 225 225

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile brick
false
0
Rectangle -1 true false 0 0 300 300
Rectangle -7500403 true true 15 225 150 285
Rectangle -7500403 true true 165 225 300 285
Rectangle -7500403 true true 75 150 210 210
Rectangle -7500403 true true 0 150 60 210
Rectangle -7500403 true true 225 150 300 210
Rectangle -7500403 true true 165 75 300 135
Rectangle -7500403 true true 15 75 150 135
Rectangle -7500403 true true 0 0 60 60
Rectangle -7500403 true true 225 0 300 60
Rectangle -7500403 true true 75 0 210 60

tile log
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 30 45 15
Line -16777216 false 45 15 120 30
Line -16777216 false 120 30 180 45
Line -16777216 false 180 45 225 45
Line -16777216 false 225 45 165 60
Line -16777216 false 165 60 120 75
Line -16777216 false 120 75 30 60
Line -16777216 false 30 60 0 60
Line -16777216 false 300 30 270 45
Line -16777216 false 270 45 255 60
Line -16777216 false 255 60 300 60
Polygon -16777216 false false 15 120 90 90 136 95 210 75 270 90 300 120 270 150 195 165 150 150 60 150 30 135
Polygon -16777216 false false 63 134 166 135 230 142 270 120 210 105 116 120 88 122
Polygon -16777216 false false 22 45 84 53 144 49 50 31
Line -16777216 false 0 180 15 180
Line -16777216 false 15 180 105 195
Line -16777216 false 105 195 180 195
Line -16777216 false 225 210 165 225
Line -16777216 false 165 225 60 225
Line -16777216 false 60 225 0 210
Line -16777216 false 300 180 264 191
Line -16777216 false 255 225 300 210
Line -16777216 false 16 196 116 211
Line -16777216 false 180 300 105 285
Line -16777216 false 135 255 240 240
Line -16777216 false 240 240 300 255
Line -16777216 false 135 255 105 285
Line -16777216 false 180 0 240 15
Line -16777216 false 240 15 300 0
Line -16777216 false 0 300 45 285
Line -16777216 false 45 285 45 270
Line -16777216 false 45 270 0 255
Polygon -16777216 false false 150 270 225 300 300 285 228 264
Line -16777216 false 223 209 255 225
Line -16777216 false 179 196 227 183
Line -16777216 false 228 183 266 192

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>score</metric>
    <metric>remaining-bees</metric>
    <enumeratedValueSet variable="nb-walls">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-bees">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pengi-halo">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-ice">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-fish">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
