# 🌟 Last Light

> **A 2D top-down survival & base-defense game built with Godot 4.**

<p align="center">
  <img src="Readme_assets/fireball.png" width="700"/>
</p>

You play as **The Keeper**, guardian of the world's final lighthouse.

Every night, shadow creatures emerge from the surrounding darkness to extinguish the Last Light. During the day, the Keeper repairs the lighthouse and prepares for the next assault.

> 📖 **Complete story, lore, mechanics, and design ideas:** `Docs/GameDesign.md`

---

# ✨ Current Features

## 🧍 Player
- 4-direction movement
- Mouse-aimed combat
- Fireball projectile system

## ⚔️ Combat
- Projectile collision detection
- Enemy health system
- Enemy death on zero HP

## 🏰 Lighthouse
- Fixed at the center of the map
- Collision system
- Health system
- Takes damage from enemies
- Repair mechanic
- Game Over state

## 👾 Enemies
- ShadowCrawler AI
- Moves toward the lighthouse
- Stops to attack in range
- Periodic damage
- Multiple enemies supported

## 🌑 Enemy Spawning
- Automatic spawning
- Configurable spawn interval

## 🌗 Day & Night Cycle

Current cycle:

```
☀️ Day
    ↓
🌇 Dusk
    ↓
🌙 Night
    ↓
🌅 Dawn
    ↓
☀️ Day
```

Enemy spawning currently occurs during the **Night** phase.

---

# 🎮 Controls

| Input | Action |
|:------:|--------|
| **W A S D** | Move |
| **Mouse** | Aim |
| **Left Click** | Shoot |
| **E** | Repair Lighthouse |

---

# 🛠 Built With

- Godot Engine **4.7**
- GDScript

---

# 📂 Project Structure

```text
Assets/
    Sprites/

Docs/
    Concepts_art/
    GameDesign.md

Scenes/
    Enemies/
    EnemySpawner/
    GameManager/
    LightHouse/
    Player/
    Projectiles/
    main.tscn

project.godot
```

---

# 🗺 Development Roadmap

- [ ] Enemy retreat during dawn
- [ ] Beacon resource system
- [ ] Resource collection
- [ ] Repair cost mechanics
- [ ] Multiple enemy types
- [ ] Progressive enemy waves
- [ ] Dynamic lighting
- [ ] Fog of Darkness
- [ ] User Interface
- [ ] Sound effects & music
- [ ] Main Menu
- [ ] Save system

---

# 🚀 Running the Project

1. Clone the repository.
2. Open using **Godot Engine 4.7** or later.
3. Run `main.tscn`.

---

# 📌 Project Status

> 🚧 **Currently in Development**

This project is being developed while learning **Godot**, **game programming**, and **game design**.

New gameplay systems and mechanics are added incrementally.

---

# 📸 Screenshots

### Enemy Spawn

<p align="center">
  <img src="Readme_assets/shadow.png" width="700"/>
</p>

---

### Combat

<p align="center">
  <img src="Readme_assets/fireball.png" width="700"/>
</p>

---

# 📜 License

This project is currently intended for **educational and portfolio purposes**.
