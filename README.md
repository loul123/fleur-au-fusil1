# 🌼 La fleur au fusil

Jeu de tir multijoueur Roblox (avec bots) dans un **potager géant** : des personnages minuscules s'affrontent entre carottes, laitues, plants de tomates, citrouilles, pots de fleurs et un arrosoir géant, armés d'un fusil avec une fleur au bout qui tire des **pétales**.

## Contenu

```
default.project.json                 → projet Rojo (optionnel)
src/shared/   (ReplicatedStorage > FleurShared)
  Config.lua          ModuleScript  – tous les réglages (armes, modes, score, bots)
  PetalVisual.lua     ModuleScript  – rendu client des pétales
src/server/   (ServerScriptService > FleurServer)
  GameManager.server.lua  Script    – boucle de jeu, modes, manches, joueurs, remotes
  Modules/
    MapBuilder.lua        ModuleScript – génère le potager géant + spawns
    ParticipantService.lua ModuleScript – joueurs/bots, touches, pénalités, score
    CombatService.lua     ModuleScript – tirs, cadence, projectiles, dégâts (autorité serveur)
    WeaponFactory.lua     ModuleScript – construit l'arme « FleurAuFusil »
    BotService.lua        ModuleScript – IA des bots
src/client/   (StarterPlayer > StarterPlayerScripts > FleurClient)
  FleurWeapon.client.lua  LocalScript – tir, viseur, recharge, hitmarker
  FleurHUD.client.lua     LocalScript – chrono, scores, classement, résultats
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
   | ServerScriptService | Folder | `FleurServer` | — |
   | ServerScriptService › FleurServer | **Script** | `GameManager` | `src/server/GameManager.server.lua` |
   | ServerScriptService › FleurServer | Folder | `Modules` | — |
   | … › FleurServer › Modules | ModuleScript | `MapBuilder` | `src/server/Modules/MapBuilder.lua` |
   | … › FleurServer › Modules | ModuleScript | `ParticipantService` | `src/server/Modules/ParticipantService.lua` |
   | … › FleurServer › Modules | ModuleScript | `CombatService` | `src/server/Modules/CombatService.lua` |
   | … › FleurServer › Modules | ModuleScript | `WeaponFactory` | `src/server/Modules/WeaponFactory.lua` |
   | … › FleurServer › Modules | ModuleScript | `BotService` | `src/server/Modules/BotService.lua` |
   | StarterPlayer › StarterPlayerScripts | Folder | `FleurClient` | — |
   | … › FleurClient | **LocalScript** | `FleurWeapon` | `src/client/FleurWeapon.client.lua` |
   | … › FleurClient | **LocalScript** | `FleurHUD` | `src/client/FleurHUD.client.lua` |

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

## Comment jouer

- **Clic gauche** (ou tap) : tirer un pétale ; **maintenir** = tir continu à la cadence de la fleur.
- **Tab** : agrandir le classement.
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
