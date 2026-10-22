# Asset Manifest

No external art, audio, or downloaded assets were added for Milestone C. New visual feedback is drawn by Godot at runtime.

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

Existing player, Lighthouse, Beacon, Shadow Crawler, and projectile sprites remain in use. Their original provenance is not recorded in this repository; Milestone C did not alter or redistribute them.
