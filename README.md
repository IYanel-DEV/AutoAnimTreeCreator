# 🎬 Auto AnimationTree Creator

<div align="center">

![Godot Version](https://img.shields.io/badge/Godot-4.x-blue?style=for-the-badge&logo=godotengine)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0-orange?style=for-the-badge)

<img width="500" height="600" alt="image" src="https://github.com/user-attachments/assets/54e01525-4d2c-46ac-83e2-44574a2ef25d" />


**Automatically generate complex AnimationTree state machines with zero coding required!**

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🚀 Overview

Auto AnimationTree Creator is a powerful Godot 4.x plugin that revolutionizes character animation workflow. It automatically generates sophisticated AnimationTree state machines with proper transitions, blend spaces, and a complete player controller script - all from your existing animations.

### ⚡ What It Does

- 🎯 **Automatic State Machine Generation** - Creates organized AnimationTree with smart transitions
- 🎮 **Complete Player Controller** - Generates ready-to-use CharacterBody3D script
- 🕹️ **Input Action Setup** - Auto-generates input map with standard controls
- 🎨 **2D Blend Spaces** - Creates directional movement blend spaces automatically
- 📁 **Organized Structure** - Categorizes animations logically (Basic, Walking, Running, Combat, etc.)
- ⚡ **Zero Configuration** - Works out of the box with intelligent defaults

## ✨ Features

### 🎭 Animation Categories

| Category | Animations | Features |
|----------|------------|----------|
| **Basic** | Idle | Core character state |
| **Walking** | Forward, Backward, Left, Right | 2D blend space for smooth movement |
| **Running** | Forward, Backward, Left, Right | Speed-based locomotion with blend space |
| **Crouching** | Idle, Forward, Backward, Left, Right | Stealth movement system |
| **Aerial** | Jump, Fall, Land | Complete air movement cycle |
| **Combat** | Attack 1-3, Block, Dodge | Combat system with timing |
| **Special** | Climb, Swim, Slide | Environmental interactions |

### 🎯 Smart Features

- **Intelligent Transitions** - Automatically creates logical state connections
- **Blend Space Integration** - Smooth directional movement without code
- **Priority-Based States** - Combat > Aerial > Movement > Idle hierarchy
- **Customizable Timing** - Different crossfade times for different transition types
- **Controller Integration** - Generated script handles all state logic

## 📦 Installation

### Method 1: Asset Library (Recommended)
1. Open Godot Engine
2. Go to **AssetLib** tab
3. Search for "Auto AnimationTree Creator"
4. Click **Install** and enable the plugin

### Method 2: Manual Installation
1. Download the latest release from GitHub
2. Extract to your project's `addons/` folder:
   ```
   your_project/
   ├── addons/
   │   └── auto_animtree_plugin/
   │       ├── plugin.cfg
   │       ├── plugin_main.gd
   │       ├── AnimationSystem.gd
   │       └── PlayerController-AnimTree.gd
   ```
3. Enable the plugin in **Project Settings > Plugins**

## 🎮 Quick Start

### 1. Setup Your Scene
```
Player (CharacterBody3D)
├── MeshInstance3D
├── CollisionShape3D
└── AnimationPlayer (with your animations)
```

### 2. Launch the Plugin
- Click the **Auto AnimTree** button in the toolbar
- Select your player scene
- Choose the AnimationPlayer node

### 3. Configure Animations
- Select which animations to use for each category
- The plugin will detect all available animations automatically

### 4. Generate Input Actions (Optional)
- Click **Auto Generate Input Actions**
- Standard movement controls will be added to your project

### 5. Create the System
- Click **Create AnimationTree & Controller**
- Your scene now has a complete animation system!

## 🎯 Generated Structure

After running the plugin, your scene will contain:

```
Player (CharacterBody3D)
├── MeshInstance3D
├── CollisionShape3D
├── AnimationPlayer (existing)
├── AnimationTree (generated)
│   └── AnimationNodeStateMachine
│       ├── Individual States
│       ├── Blend Spaces (walk/run/crouch)
│       └── Smart Transitions
└── PlayerController.gd (generated script)
```

## 📖 Documentation

### Generated Input Actions

| Action | Default Keys | Purpose |
|--------|-------------|---------|
| `move_forward` | W, ↑ | Move forward |
| `move_back` | S, ↓ | Move backward |
| `move_left` | A, ← | Move left |
| `move_right` | D, → | Move right |
| `jump` | Space | Jump action |
| `run` | Shift | Sprint modifier |
| `crouch` | C | Crouch toggle |
| `attack` | E | Primary attack |
| `block` | Q | Block/defend |
| `dodge` | X | Dodge roll |

### Controller API

The generated controller provides these public methods:

```gdscript
# Animation control
func play_animation(state_name: String)
func has_animation_state(state_name: String) -> bool
func get_current_animation_state() -> String

# State queries  
func can_attack() -> bool
func can_block() -> bool
func can_dodge() -> bool
func is_in_air() -> bool

# Debug
func print_current_state()
```

### Customization

#### Movement Parameters
```gdscript
var speed: float = 5.0
var run_speed_multiplier: float = 2.0
var crouch_speed_multiplier: float = 0.5
var jump_force: float = 12.0
var gravity: float = 20.0
```

#### Animation Timers
```gdscript
var attack_duration: float = 0.5
var dodge_duration: float = 0.3
```

## 🎨 Advanced Usage

### Custom Transitions
The generated state machine includes intelligent transition types:

- **Instant Transitions** (0.0s) - Jump states, combat attacks
- **Standard Transitions** (0.2s) - Most movement changes
- **Slow Transitions** (0.5s) - Crouch/stand transitions

### Blend Space Parameters
Generated blend spaces use normalized Vector2 coordinates:
- **Forward**: (0, -1)
- **Backward**: (0, 1)  
- **Left**: (-1, 0)
- **Right**: (1, 0)

### State Priority System
```
Combat (Attack/Block/Dodge)
	↓
Aerial (Jump/Fall/Land)
	↓
Ground Movement (Walk/Run/Crouch)
	↓
Idle
```

## 🛠️ Troubleshooting

### Common Issues

**Plugin button not visible:**
- Ensure plugin is enabled in Project Settings
- Restart Godot after installation

**Animations not detected:**
- Check AnimationPlayer has animations loaded
- Verify animation names match expected patterns

**Generated script errors:**
- Ensure CharacterBody3D setup is correct
- Check that all referenced nodes exist

**Input actions not working:**
- Save project and restart after generating inputs
- Manually check Project Settings > Input Map

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch
3. **Commit** your changes
4. **Push** to the branch
5. **Open** a Pull Request

### Development Setup
```bash
git clone https://github.com/IYanel-DEV/AutoAnimTreeCreator.git
cd AutoAnimTreeCreator
# Open in Godot and enable plugin
```

### Reporting Issues
- Use the GitHub issue tracker
- Include Godot version and error messages
- Provide minimal reproduction steps

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Support

- ⭐ **Star** this repository if you find it useful
- 🐛 **Report bugs** via GitHub Issues  
- 💡 **Request features** in Discussions
- 📖 **Contribute** to documentation

---

<div align="center">

**Made with ❤️ for the Godot Community**

[⬆ Back to Top](#-auto-animationtree-creator)

</div>
