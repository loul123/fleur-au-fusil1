# 🌼 La fleur au fusil

Jeu de tir multijoueur Roblox (avec bots) dans **11 potagers géants** (vote de carte entre les parties) : des personnages minuscules s'affrontent entre carottes, laitues, plants de tomates, citrouilles, pots de fleurs et un arrosoir géant, armés d'un fusil avec une fleur au bout qui tire des **pétales**.

## Contenu

```
default.project.json                 → projet Rojo (optionnel)
src/shared/   (ReplicatedStorage > FleurShared)
  Config.lua          ModuleScript  – tous les réglages (armes, modes, score, bots)
  PetalVisual.lua     ModuleScript  – rendu client des pétales et de leurs animations
  Cosmetics.lua       ModuleScript  – catalogue des skins d'arme, fleurs, animations de pétales
  WeaponFactory.lua   ModuleScript  – construit le fusil à fleur (Tool + aperçu 3D)
src/server/   (ServerScriptService > FleurServer)
  GameManager.server.lua  Script    – boucle de jeu, modes, manches, joueurs, remotes
  Modules/
    MapBuilder.lua        ModuleScript – génère les 11 potagers (thèmes) + spawns
    ParticipantService.lua ModuleScript – joueurs/bots, touches, pénalités, score
    CombatService.lua     ModuleScript – tirs, cadence, projectiles, dégâts (autorité serveur)
    BattlePassService.lua ModuleScript – pass de saison, graines, casier, sauvegarde, Game Pass
    BotService.lua        ModuleScript – IA des bots
src/client/   (StarterPlayer > StarterPlayerScripts > FleurClient)
  FleurWeapon.client.lua  LocalScript – tir, viseur, recharge, hitmarker
  FleurHUD.client.lua     LocalScript – chrono, scores, classement, résultats, vote de carte
  FleurPass.client.lua    LocalScript – fenêtre du pass, casier avec aperçu 3D, notifications de graines
```

L'arme, la carte, les équipes et les RemoteEvents sont **créés par code** : aucun modèle à importer.

## Installation dans Roblox Studio (copier-coller)

1. Créez une place (template **Baseplate** ou **Flat Terrain**). Le Baseplate et la SpawnLocation par défaut sont supprimés automatiquement.
2. Dans l'**Explorer**, créez exactement cette arborescence (clic droit → *Insert Object*) et collez le contenu de chaque fichier dans le script du même nom :

   | Emplacement | Type | Nom | Fichier |
   |---|---|---|---|
   | ReplicatedStorage | Folder | `FleurShared` | — |
   | ReplicatedStorage › FleurShared | ModuleScript | `Config` | `src/shared/Config.lua` |
   | ReplicatedStorage › FleurShared | ModuleScript | `PetalVisual` | `src/shared/PetalVisual.lua` |
   | ReplicatedStorage › FleurShared | ModuleScript | `Cosmetics` | `src/shared/Cosmetics.lua` |
   | ReplicatedStorage › FleurShared | ModuleScript | `WeaponFactory` | `src/shared/WeaponFactory.lua` |
   | ServerScriptService | Folder | `FleurServer` | — |
   | ServerScriptService › FleurServer | **Script** | `GameManager` | `src/server/GameManager.server.lua` |
   | ServerScriptService › FleurServer | Folder | `Modules` | — |
   | … › FleurServer › Modules | ModuleScript | `MapBuilder` | `src/server/Modules/MapBuilder.lua` |
   | … › FleurServer › Modules | ModuleScript | `ParticipantService` | `src/server/Modules/ParticipantService.lua` |
   | … › FleurServer › Modules | ModuleScript | `CombatService` | `src/server/Modules/CombatService.lua` |
   | … › FleurServer › Modules | ModuleScript | `BattlePassService` | `src/server/Modules/BattlePassService.lua` |
   | … › FleurServer › Modules | ModuleScript | `BotService` | `src/server/Modules/BotService.lua` |
   | StarterPlayer › StarterPlayerScripts | Folder | `FleurClient` | — |
   | … › FleurClient | **LocalScript** | `FleurWeapon` | `src/client/FleurWeapon.client.lua` |
   | … › FleurClient | **LocalScript** | `FleurHUD` | `src/client/FleurHUD.client.lua` |
   | … › FleurClient | **LocalScript** | `FleurPass` | `src/client/FleurPass.client.lua` |

   ⚠ Si vous aviez installé une version précédente : `WeaponFactory` a **déménagé** de `ServerScriptService › FleurServer › Modules` vers `ReplicatedStorage › FleurShared` (supprimez l'ancien).

   Les noms doivent être identiques (les scripts se trouvent par `WaitForChild`).
3. **Game Settings › Avatar** : choisissez **R15** (recommandé ; les bots sont en R15).
4. Lancez **Play** (F5). Seul, vous jouez contre des bots ; pour du multijoueur local : onglet *Test* → *Clients and Servers* → 2+ joueurs.
5. Publiez (*File › Publish to Roblox*) pour jouer en ligne.

### Avec Rojo

```bash
rojo serve        # puis « Connect » dans le plugin Rojo de Studio
# ou
rojo build -o LaFleurAuFusil.rbxlx
```

## L'arme
Fusil d'assaut stylisé construit par code : crosse, carcasse, lunette, chargeur courbe, garde-main ajouré, poignée verticale, guidon et cache-flamme, avec une **marguerite au bout du canon** (tige, deux feuilles, cœur jaune, pétales blancs vus de profil). Skin par défaut « Classique » orange/jaune/gris. Les pétales partent du cœur de la fleur. Taille globale : `SCALE` dans `WeaponFactory.lua`.

## Pass de saison (battle pass)

### Graines 🌱
À la fin de chaque partie, chaque joueur gagne des graines selon ses statistiques (`Config.BattlePass.Seeds`) :
- Victoire : +40 (équipe gagnante en mode équipe, vainqueur en chacun pour soi / Gun Game)
- +1 par touche, +1 pour 20 points de score final, +10 par point de ratio (max +30), MVP +15
- En cas de défaite : 30 % du total (`LoserShare`, mettez 0 pour réserver les graines aux gagnants)
- Pass Premium : +20 % (`PremiumSeedBonus`) ; plafond 250 par partie ; un joueur inactif (0 touche donnée/reçue) ne gagne rien.

### Paliers et récompenses
`Config.BattlePass.Tiers` : chaque palier demande un total de graines dans la saison et donne une récompense **gratuite** (`Free`) et/ou **premium** (`Premium`). Les récompenses sont attribuées automatiquement ; si le Pass Premium est acheté en cours de saison, les récompenses premium des paliers déjà atteints sont données immédiatement.

⚠ Les récompenses actuelles sont des **exemples**. Pour mettre les vôtres :
1. créez l'objet dans `src/shared/Cosmetics.lua` (skin d'arme : couleurs Body/Accent/Metal/Dark + matériau ; fleur : couleur des pétales/cœur/tige, nombre et forme des pétales ; animation de pétales : traînée, étincelles, orbite, impact `Burst`/`Hearts`/`Rain`) ;
2. référencez son `Id` dans un palier : `{ Seeds = 1000, Free = { Type = "FlowerSkin", Id = "MonId" }, Premium = { ... } }`.

### Les 100 fleurs
Toutes les fleurs (#100 Marguerite Blanche → #1 La Fleur de l'Infini) sont dans `Cosmetics.FlowerSkins`. Chaque fleur a ses couleurs, son nombre et sa forme de pétales ; les plus rares ont plusieurs couronnes, des matériaux spéciaux (verre, glace, néon, métal, lave, champ de force), une aura de particules et une lumière. La Marguerite Blanche est la fleur de départ. Les pétales tirés prennent la couleur de la fleur équipée.

| Rareté | Fleurs | Sachet de graines | Sachet doré | Doublon remboursé |
|---|---|---|---|---|
| Commune | #100–81 | 55 % | — | 10 |
| Peu commune | #80–61 | 25 % | — | 20 |
| Rare | #60–41 | 12 % | 70 % | 40 |
| Épique | #40–26 | 5 % | 20 % | 80 |
| Légendaire | #25–16 | 2 % | 7 % | 150 |
| Mythique | #15–10 | 0,7 % | 2,2 % | 300 |
| Divin | #9–6 | 0,2 % | 0,6 % | 600 |
| Secret | #5–3 | 0,08 % | 0,15 % | 1 200 |
| Secret / Transcendant | #2 | 0,019 % | 0,049 % | 2 500 |
| Ultime | #1 | **0,001 %** | **0,001 %** | 5 000 |

Dans une rareté, chaque fleur a la même chance.

### Deux compteurs de graines
- **Progression du pass** : toutes les graines gagnées ; elle ne baisse jamais et débloque les paliers.
- **Solde** : les mêmes graines, plus les remboursements de doublons ; on le dépense pour ouvrir des sachets (150 pour un sachet, 600 pour un sachet doré).

### Ce que donne le pass (30 paliers, 60 → 8 700 graines)
- **Piste gratuite** : les 19 fleurs communes (la Marguerite Blanche est déjà possédée), 7 sachets, 1 sachet doré, le skin d'arme Camouflage Potager, 2 animations de pétales.
- **Piste premium** : 10 fleurs peu communes, 6 rares, 3 épiques, la Fleur de Crépuscule (légendaire), 3 sachets dorés, 4 skins d'arme, 3 animations.
- **Mythique, Divin, Secret, Transcendant et Ultime** ne s'obtiennent qu'en sachet. Quand quelqu'un tire une fleur Mythique ou plus, tout le serveur est prévenu.

Pour réorganiser : modifiez `Config.BattlePass.Tiers` (`Type = "FlowerSkin"` + Id de la fleur, ou `Type = "Pack", Id = "Sachet"`/`"SachetDore"`, `Count = n`). Probabilités et prix des sachets : `Cosmetics.Packs`.

### Rendre le pass payant
1. Publiez le jeu, puis sur create.roblox.com › votre expérience › **Monétisation › Passes**, créez un pass « Pass Premium — Saison 1 » et fixez son prix.
2. Copiez son ID dans `Config.BattlePass.GamePassId`.
3. Le bouton « Débloquer le Pass Premium » ouvre l'achat Roblox (prix affiché automatiquement). Sans ID, dans Studio, ce bouton débloque le premium gratuitement pour tester (`StudioFreePremium`).
4. Nouvelle saison : changez `Season`, `SeasonName`, les paliers et créez un nouveau Game Pass. Les graines repartent à zéro, les objets gagnés sont conservés.

### Boutique Robux
Deux choses se paient en Robux :

| Achat | Type Roblox | Où configurer |
|---|---|---|
| Pass Premium de la saison | **Game Pass** (achat unique) | `Config.BattlePass.GamePassId` |
| Sachet de graines ×1 / ×5 | **Developer Product** (achat répétable) | `Config.Shop.Products` (`Sachet1`, `Sachet5`) |
| Sachet doré ×1 / ×5 | **Developer Product** | `Config.Shop.Products` (`SachetDore1`, `SachetDore5`) |

Mise en place :
1. Publiez le jeu puis, sur create.roblox.com › votre expérience › **Monétisation** :
   - **Passes** : créez « Pass Premium — Saison 1 », fixez le prix, copiez l'ID dans `GamePassId` ;
   - **Produits pour développeurs** : créez les 4 produits (ex. « Sachet de graines ×1 », « ×5 », « Sachet doré ×1 », « ×5 »), fixez les prix, copiez chaque ID dans le `ProductId` correspondant.
2. Les prix affichés en jeu sont lus automatiquement chez Roblox.
3. Les sachets achetés vont dans le stock du joueur (onglet Sachets) ; il les ouvre quand il veut.

Sécurité des achats :
- `ProcessReceipt` mémorise chaque reçu : un achat n'est jamais crédité deux fois ;
- le profil est sauvegardé tout de suite, et si la sauvegarde échoue, l'achat est annulé et Roblox le renverra plus tard (le joueur ne perd rien) ;
- les probabilités sont affichées à côté des boutons d'achat (règle Roblox pour les objets aléatoires payants) ;
- les joueurs des pays où les objets aléatoires payants sont interdits (`PolicyService`) ne voient pas les boutons Robux des sachets et ne peuvent pas les acheter ; ils peuvent toujours les ouvrir avec des graines.

Test dans Studio : tant que les ID valent 0, l'achat du pass et des sachets est simulé gratuitement (`StudioFreePremium`, `StudioFreeProducts`). Les vrais achats ne sont possibles que sur le jeu publié (dans Studio, Roblox simule les achats sans débiter).

### Sauvegarde
Profils enregistrés en DataStore (`FleurAuFusil_Profils_v1`) : graines, objets possédés, tenue équipée. Pour tester dans Studio : **Game Settings › Security › Enable Studio Access to API Services**. Sans cela, tout fonctionne mais rien n'est sauvegardé (le titre du pass affiche « non sauvegardé »).

### Interface
- **B** ou bouton « 🌱 Pass » : piste gratuite en haut, premium en bas, progression vers le prochain palier, bouton d'achat.
- Onglet **Sachets** : stock, prix, probabilités par rareté, bouton d'ouverture et révélation animée de la fleur en 3D.
- Onglet **Casier** : aperçu 3D tournant de l'arme, et tous les objets (possédés ou 🔒) ; cliquez pour équiper un skin d'arme, une fleur ou une animation de pétales. Les autres joueurs voient votre arme et vos pétales.
- Fin de partie : fenêtre « +N graines » avec le détail, puis une notification pour chaque nouvelle récompense.
- Les bots portent des skins au hasard (vitrine des récompenses).

## Comment jouer

- **Clic gauche** (ou tap) : tirer un pétale ; **maintenir** = tir continu à la cadence de la fleur.
- **Tab** : agrandir le classement. **B** : pass de saison et casier.
- L'arme est équipée automatiquement à chaque apparition.

## Règles

### Arme et cadence
Chaque fleur a un **cooldown** entre deux tirs, appliqué côté client (confort) **et côté serveur** (anti-spam : un tir trop rapproché est refusé). Les pétales sont des projectiles simulés par le serveur (vitesse + légère gravité, détection par `Spherecast`) ; les clients n'affichent qu'une copie visuelle.

| Palier | Fleur | Cadence | Dégâts | Particularité |
|---|---|---|---|---|
| 1 | Pâquerette | 0,35 s | 20 | arme de base |
| 2 | Marguerite | 0,25 s | 17 | plus rapide |
| 3 | Tulipe | 0,65 s | 14 ×4 | gerbe (fusil à pompe) |
| 4 | Tournesol | 0,11 s | 9 | mitrailleuse |
| 5 | Rose | 0,95 s | 55 | précision (sniper) |
| 6 | Lys | 0,45 s | 22 ×2 | double pétale |
| 7 | Pissenlit | 0,08 s | 7 | arrosage imprécis |
| 8 | Orchidée | 0,30 s | 35 | arme finale |

### Score
- Chaque **touche donnée** : **+10 points**.
- Chaque **touche reçue** : **−5 points de pénalité**.
- **Ratio** = touches données / max(1, touches reçues).
- **Score final** = (touches×10 − reçues×5) × multiplicateur, avec multiplicateur = 0,5 + ratio×0,5, borné entre ×0,5 et ×2 (un score négatif n'est pas multiplié).
  Exemple : 30 touches, 15 reçues → base 225, ratio 2 → ×1,5 → **338**.

Tout est réglable dans `Config.Scoring` / `Config.ComputeScore`.

Une jauge de vitalité (100) s'ajoute : un personnage dont la vitalité tombe à 0 est « fané » et réapparaît 4 s plus tard (protégé 2,5 s).

### Modes (rotation automatique)
1. **Match à mort par équipe** (Coquelicots 🔴 contre Bleuets 🔵) : manches de 3 min, la première équipe à 40 touches gagne la manche, au meilleur des 3 manches. Pas de tir ami. Brassard de couleur pour reconnaître son équipe.
2. **Chacun pour soi** : manches de 2 min 30, premier à 20 touches, au meilleur des 3 manches.
3. **Gun Game : premier à 200 touches** : la fleur évolue toutes les 25 touches (8 paliers), le premier à 200 touches gagne.

Un écran de résultats affiche à la fin le vainqueur, le MVP et pour chacun touches / reçues / ratio / score final.

## Cartes : 10 potagers + 1 « multi »

| Id | Carte | Légumes | Monument central | Ambiance |
|---|---|---|---|---|
| `Tomates` | Le Rang des Tomates | plants de tomates sur tuteurs | arrosoir géant | midi |
| `Ail` | Le Champ d'Ail | têtes d'ail et longues tiges | brouette géante | matin |
| `Carottes` | Le Carré de Carottes | carottes aux grandes fanes | nain de jardin | midi |
| `Citrouilles` | Le Champ de Citrouilles | citrouilles énormes | épouvantail | crépuscule orangé |
| `Salades` | Le Jardin des Salades | laitues et radis | arrosoir géant | ciel couvert |
| `Fraises` | Le Fraisier | fraisiers sur rangs de paille | brouette géante | après-midi |
| `Mais` | Le Labyrinthe de Maïs | maïs de 70 à 95 studs, rangs serrés avec passages | épouvantail | fin d'après-midi |
| `Choux` | Le Potager de Choux | choux verts et rouges | nain de jardin | brume du matin |
| `Piments` | Le Coin des Piments | poivrons et piments | arrosoir géant | plein soleil |
| `Tournesols` | Le Champ de Tournesols | tournesols géants | nain de jardin | soleil couchant |
| `Multi` | Le Grand Potager | chaque rang a un légume différent (les 10) | arrosoir géant + tous les décors | midi |

Toutes les cartes gardent la même base (clôture, 9 rangs, spawns des deux camps et neutres) pour rester équilibrées. Seuls les légumes, leur densité, le sol, les décors, les paquets de graines et la lumière changent.

**Choix de la carte** (`Config.MapSelection`) :
- `Mode = "Vote"` (par défaut) : pendant l'intermission, 3 cartes au hasard (hors carte actuelle) sont proposées en bas de l'écran ; chaque joueur clique pour voter. La carte qui a le plus de voix l'emporte, une égalité est tirée au sort.
- `"Rotation"` : les cartes s'enchaînent dans l'ordre de `Config.Maps`. `"Random"` : une carte au hasard.
- `StartMap` : carte chargée au démarrage du serveur (`"Multi"` par défaut).

Pour ajouter une carte : ajoutez une entrée dans `Config.Maps` et un thème du même Id dans la table `THEMES` de `MapBuilder.lua`.

## Bots
- Ils complètent la partie jusqu'à **6 combattants** (`Config.Bots.FillTo`) : seul sur le serveur, vous avez 5 adversaires ; un bot part chaque fois qu'un joueur arrive.
- Leur IA : cible l'ennemi visible le plus proche, se tourne vers lui, tire à la cadence de sa fleur en visant devant la cible et en compensant la chute du pétale, garde une distance de combat et se décale sur le côté (strafe) ; sinon se déplace par `PathfindingService` vers l'ennemi le plus proche, avec détection de blocage.
- Difficulté : `AimErrorDegrees` (imprécision), `ReactionTime`, `LeadSkill`, `WalkSpeed`.
- `Config.Bots.Enabled = false` pour les désactiver.

## Personnalisation
- **Votre propre potager** : mettez `Config.Map.Generate = false`, construisez un Model/Folder `PotagerGeant` dans Workspace et ajoutez des `SpawnLocation` nommées `Spawn_Coquelicots`, `Spawn_Bleuets` et `Spawn_Neutre`.
- **Personnages encore plus petits** : `Config.Map.CharacterScale = 0.6`.
- **Ordre des modes** : `Config.ModeRotation`. **Durées / objectifs** : `Config.Modes`.
- **Sons** : `Config.Sounds` (remplacez par vos assets).

## Notes techniques
- Le serveur fait autorité : cadence, origine du tir (tolérance 14 studs), dégâts, tir ami et protection d'apparition sont vérifiés côté serveur.
- Joueurs et bots passent par le même `CombatService.TryFire` : mêmes règles pour tous.
- Les animations des bots utilisent les animations R15 par défaut de Roblox ; si elles ne se chargent pas, les bots glissent mais restent fonctionnels.
