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

## Milestone G — Stage 1: Lighthouse Yard environment

Six pixel-art assets were generated for the Lighthouse Yard surface. They are pixel art produced with Ziva's built-in image generation tool from text prompts only (no reference images, no third-party asset packs, no downloads). They are original to this project and carry no external license terms. All are imported with nearest-neighbour filtering and used at 1:1 pixel scale.

| Asset | Path | Purpose | Notes |
|---|---|---|---|
| Yard ground tile | `Assets/generated/yard_ground.png` | Seamless 64×64 muted blue-grey stone/earth surface for the lit Yard | Opaque tile; repeated with Sprite2D `region_rect` + `texture_repeat` |
| Void tile | `Assets/generated/yard_void.png` | Seamless near-black 64×64 ground for the darkness beyond the Yard | Opaque; gives the Yard a readable edge without collision |
| Worn path tile | `Assets/generated/yard_path.png` | Seamless 64×64 weathered flagstone path | Opaque; drawn as a crossroads through the Lighthouse |
| Shoreline rocks | `Assets/generated/yard_rocks.png` | 64×64 transparent prop | Non-colliding decoration |
| Sea-grass tuft | `Assets/generated/yard_grass.png` | 48×48 transparent prop | Non-colliding decoration |
| Weathered ruin | `Assets/generated/yard_ruin.png` | 64×64 transparent prop | Non-colliding decoration |

All six assets are visual only: none adds collision shapes, detection areas, or gameplay behaviour. The Yard's ground, void, path, and prop nodes are `Sprite2D` decorations placed below the existing entities (negative `z_index`) and do not alter combat, movement, interaction zones, or the retreat boundaries.

## Milestone G — Stage 1B: Lighthouse Yard composition

Stage 1B refined the Yard's framing, ground/path transition, and Lighthouse presentation. Three further pixel-art assets were generated the same way (Ziva's image tool from text prompts only; original to this project, no external license terms). The Yard ground was enlarged from 640×640 to 960×576 and the Yard-local `Camera2D` was given limits of ±480 × ±288 in `Scenes/Worlds/LighthouseYard.tscn` (a per-instance override, so expeditions are unaffected). The Lighthouse glow is a procedural `GradientTexture2D` radial gradient with an additive `CanvasItemMaterial` behind the Lighthouse sprite — no image file.

| Asset | Path | Purpose | Notes |
|---|---|---|---|
| Worn path (vertical) | `Assets/generated/yard_path_v.png` | Seamless 64×64 vertical footpath whose edges fade into the yard ground | Replaces `yard_path.png` for the N–S path |
| Worn path (horizontal) | `Assets/generated/yard_path_h.png` | Seamless 64×64 horizontal footpath whose edges fade into the yard ground | Replaces `yard_path.png` for the E–W path |
| Ground details | `Assets/generated/yard_details.png` | 48×48 transparent prop (worn paving stone + scattered pebbles) | Non-colliding decoration |

Superseded / unused generated files (kept on disk, not referenced by any scene; may be removed on request): `Assets/generated/yard_path.png` (replaced by `yard_path_v.png`/`yard_path_h.png`) and `Assets/generated/yard_glow.png` (replaced by the procedural `GradientTexture2D` glow).

All Stage 1B assets are visual only. The glow sits at `z_index = -9` (behind all entities, below the Lighthouse sprite) so it does not alter enemy status tints or any gameplay-relevant colour.
