# Asset Manifest

No external art, audio, or downloaded assets were added for Milestones C or D. New visual feedback and expedition environment art are drawn by Godot at runtime.

| Asset or effect | Source | In-game purpose | Notes |
|---|---|---|---|
| Focus cone | `Scenes/Player/PlayerLight.gd` | Shows the player-directed focused beam | Procedural CanvasItem polygon; its radius and angle match enemy filtering. |
| Lighthouse sweep | `Scenes/LightHouse/LighthouseBeam.gd` | Shows the rotating lighthouse beam | Procedural cone; enemy slow applies inside the same range and angle. |
| Combat burst | `Scenes/Effects/CombatBurst.gd` | Hit, repair, pickup, build, trap, and destruction feedback | Procedural ring and spokes; no external texture. |
| Defense site markers | `Scenes/Defenses/BuildSite.gd` | Marks available fixed construction points | Procedural marker; the HUD prompt displays build cost. |
| Thorn Barricade | `Scenes/Defenses/ThornBarricade.gd` | Visualizes a blocking structure and its durability | Procedural planks, thorns, and durability bar. |
| Snare Trap | `Scenes/Defenses/SnareTrap.gd` | Shows an armed trap and its one-shot trigger | Procedural rune and trigger burst. |
| Ward Lantern | `Scenes/Defenses/WardLantern.gd` | Shows the lantern and its slow field | Procedural field ring and lantern glyph. |
| Salvage pickup | `Scenes/Resources/SalvagePickup.gd` | Marks collectible build material | Procedural scrap shard; no external texture. |
| Nightstalker | `Scenes/Enemies/Nightstalker.gd` | Identifies the player hunter and its attack windup | Procedural silhouette and warning arc. |
| Light Leech | `Scenes/Enemies/LightLeech.gd` | Shows the lighthouse suppression field | Procedural outline and pulse ring; suppression clears when defeated. |
| Ashen Brute | `Scenes/Enemies/AshenBrute.gd` | Shows armor and the focused-light exposure state | Procedural armored silhouette and exposed outline. |
| Bell-Taker | `Scenes/Enemies/BellTaker.gd` | Telegraphs its darkness pulse | Procedural warning ring, bell glyph, and timed CanvasModulate pulse. |
| Expedition terrain | `Scenes/Expeditions/ExpeditionController.gd` | Gives each map a distinct beach, forest, or flooded-chapel palette | Procedural ground, tide, trees, stonework, and route markers. |
| Wreckage and ruins | `Scenes/Expeditions/ExpeditionObstacle.gd` | Provides traversable-map obstacles | Collision-backed wreck, rock, tree, and pillar shapes drawn at runtime. |
| Veil barrier | `Scenes/Expeditions/VeilBarrier.gd` | Marks the light-revealed Saltwood route | Visible progress bar and blocking collision that clears under focused light. |
| Prism Shard | `Scenes/Expeditions/PrismShard.gd` | Marks the required campaign objective | Procedural shard glyph; collection persists through extraction. |
| Story fragments | `Scenes/Expeditions/StoryClue.gd` | Presents the previous Keeper's expedition clues | Procedural journal slip with one-time campaign recording. |
| Expedition board and extraction | `Scenes/Expeditions/ExpeditionBoard.gd`, `ExpeditionExit.gd` | Shows mission availability and the return point | Procedural route markers with contextual interaction prompts. |
| Night wave configurations | `Scenes/EnemySpawner/Configs/Night1.tres`–`Night4.tres` | Defines enemy mixes, spawn timing, night limits, and special events | Data-authored waves use the existing enemy scenes. |
| Eclipse Surge and Red Moon | `Scenes/EnemySpawner/EnemySpawner.gd`, `Scenes/LightHouse/LighthouseBeam.gd` | Shows temporary beam suppression and a more aggressive, more rewarding wave | Gameplay modifiers and notices share the event timer. |
| Memory Echo and lens choices | `Scenes/HUD.gd`, `Scenes/Worlds/DawnLensConsole.gd` | Presents upgrade rewards and the Day 5 lens tuning | HUD panels are built with Godot controls; the console draws installed shards procedurally. |

Existing player, Lighthouse, Beacon, Shadow Crawler, and projectile sprites remain in use. Their original provenance is not recorded in this repository; Milestones C and D did not alter or redistribute them.
