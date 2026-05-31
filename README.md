# 🐊 ANGRY BRAINROT

Free-to-play slingshot game for Android — Angry Birds mechanics + original absurdist brainrot characters.

**Target audience:** Kids 7-10 years old  
**Stack:** Godot 4.3, Android  
**Monetization:** Free + IAP (characters, power-ups, episode packs, remove ads)

---

## Characters

| Character | Ability | Unlock |
|---|---|---|
| 🐊 Bombardiro Crocodilo | Explose à l'impact, dégâts zone — BOMBARDIRO!!! | Free |
| 🦫 Capybara Chill | Traverse toutes les structures (pierce) | Free |
| 🦈 Tralalero Tralala | Rebondit 3x, chaque rebond = dégâts + son | Free |
| 🪿 Bombombini Gusini | Tourne comme une toupie, détruit la pierre | IAP $0.99 |
| 🕷️ Brr Brr Patapim | Se divise en 3 projectiles en plein vol | IAP $1.99 |

## Monetization (COPPA 2.0 compliant)

- **Remove Ads** — $2.99 one-time
- **Character packs** — $0.99–$1.99 each
- **Power-up packs** — $0.99 (5x power-ups)
- **Episode 2** (20 new levels) — $1.99
- All IAP behind parental gate (math question)
- AdMob family-safe only, never during gameplay

## Project Structure

```
angry-brainrot/
├── scripts/
│   ├── core/
│   │   ├── GameManager.gd     # Singleton, save/IAP state
│   │   ├── Slingshot.gd       # Drag/launch physics
│   │   ├── LevelManager.gd    # Win/lose/stars logic
│   │   ├── Structure.gd       # Destructible wood/stone/ice
│   │   └── Enemy.gd           # Enemy with health + defeat
│   ├── characters/
│   │   ├── BaseCharacter.gd       # Base class for all birds
│   │   ├── BombardiroCrocodilo.gd # Explosion on impact (free)
│   │   ├── CapybaraChill.gd       # Pierce through (free)
│   │   ├── TralalerTralala.gd     # 3x bounce (free)
│   │   ├── BombombiniGusini.gd    # Spin attack — IAP $0.99
│   │   └── BrrBrrPatapim.gd       # Split x3 — IAP $1.99
│   └── ui/
│       ├── MainMenu.gd
│       ├── LevelSelect.gd
│       ├── HUD.gd
│       └── Shop.gd            # IAP + parental gate
├── scenes/
│   ├── ui/
│   ├── levels/
│   └── characters/
└── assets/
    ├── sprites/
    ├── sounds/
    └── fonts/
```

## Setup

1. Install [Godot 4.3](https://godotengine.org/)
2. Open `project.godot`
3. Add autoload: `GameManager.gd` → singleton name `GameManager`
4. For Android export: install Android export templates + GodotGooglePlayBilling plugin

## COPPA 2.0 Compliance

- No personal data collected
- No behavioral advertising
- No cross-app tracking
- AdMob in `child-directed` mode only
- Parental gate (math question) before every IAP
- `TAG_FOR_CHILD_DIRECTED_TREATMENT=true` in AdMob config
- Declare "Designed for Families" on Google Play Console
