# 3D Game Creation

in Godot 4.7+

> Note: this is a living document, it might change each time we progress in our game creation. It is therefore not finished, unless we state it here.

## Scene Layout

> Note: In our case, backgrounds are generated procedurally through a script. Thus, there is no specific nodeItem for it.

```
Node3D.tscn – script: WeatherManagement.gd > Then drop “Player” on the Follow Target param.
├── WorldEnvironment > Environment > Sky > sky.gdshader (rain, clouds)
├── Weather3D (a MultiMeshInstance3D required by WeatherManagement.gd)
├── Player.tscn – script: Movement.gd
│   ├── CollisionShape3D > (CapsuleShape3D)
│   └── Camera 3D – script: FOV.gd
├── Enemy.tscn
│   └── CharacterBody3D – script: Enemy.gd or Skeleton.gd
│       ├── CollisionShape3D > (CapsuleShape3D)
│       ├── MeshInstance3D (This later becomes a .FBX, or .OBJ)
│       └── NavigationAgent3D (at city level we also need a NavigationRegion3D!)
├── DirectionalLight3D
├── NavigationRegion3D
│   └── StaticBody3D (Ground)
│       ├── MeshInstance3D
│       └── CollisionShape3D
├── CanvasLayer – script: HUD.gd
│   └── Crosshair – script: Crosshair.gd
└── HUD
│    ├── Toaster – script: Toaster.gd
│   │   └── MarginContainer
│   │       └── TextureRect
│   ├── Panel
│   │   ├── RadarIcon (TextureRect)
│   │   └── TextureRect
│   ├── AmmoPanel
│   │   ├── AmmoLabel (RichTextLabel)
│   │   ├── AmmoBar (ProgressBar)
│   │   └── AmmoIcon (TextureRect)
│   └── HealthPanel
│       ├── HealthLabel (RichTextLabel)
│       ├── HealthBar (ProgressBar)
│       └── HealthIcon (TextureRect)
└── Console (MarginContainer)
│    └── ConsolePanel (Panel) - script: Console.gd
│       ├── Log (RichTextLabel)
│       └── CommandInput (LineEdit)
└── DeathScreen (CanvasLayer) - script: DeathScreen.gd
```

**Node3D.tscn**

Click the main **Node3D**, assign the WeatherMangement script. Then in inspector: Follow Target; select “Player”

## Player

Create a seperate .tscn scene for the Player, so that it holds it’s own scene. This is useful for many reasons. Also create the Camera3D inside of that scene. Then drag the scene unto the 3D world, and set the camera to about 1.6 meters height.

## DirectionalLight3D

<ins>Properties:</ins>\
Sky Mode: Light and Sky.\
Color: #b8c8ff\
Energy: 1.6

## NavigationRegion3D

```
NavigationRegion3D > Select default navgination mesh
└── StaticBody3D (Rename to: Ground)
    ├── MeshInstance3D > BoxMesh > Click tiny arrow, > Edit, set size to ~X: 600 Y: 1 Z: 600
    └── CollisionShape3D > BoxShape > Click tiny arrow, > Edit, set size to ~X: 600 Y: 1 Z: 600
```

Gotcha’s. After setting up all these childnodes, click “<ins>bake navigation mesh</ins>” in the 3D window. Do not forget this! *Later on, you could import a SRTM mesh from OSM data to have real terrain… the principle remains the same.*

To color the ground, first create a new shader called *Ground.gdshader*. Then Select MeshInstance3D > New Material > Shader > select the new shader.

## HUD

**HUD Layout:**

```
    Layout > Anchors Preset > Top Left. (Places the HUD top left screen in viewport)
```

**HUD UI Icons:**

```
    Expand Mode: Keep Size
    Strech Mode: Keep Centered
```

**Attach a script to a node**

To attach more scripts, we can create sub-nodes/panels and add a script to each which then select the parent node. This avoids the one-script limitation per node in Godot.

Example:

```
Console (MarginContainer)
└── ConsolePanel (Panel) - script: Console.gd
    ├── Log (RichTextLabel)
    └── CommandInput (LineEdit)
```

Select the parent through a script:

```
# Node is the ConsolePanel where this script is dropped on.
extends Node
# Get "Console" by selecting the parent:
@onready var console: MarginContainer = get_parent()
```

**HUD UI Gotcha’s:**

Most “unclickable” items in the HUD need to ignore the mouse, otherwise it can (b)lock the mouse:

```
    HUD Item > Mouse > Filter: Ignore.
```

If you ever add HUD elements that should be interactive – a pause menu button, an inventory slot you click on, a settings toggle – those need **Filter: Stop (or Pass)** specifically, while everything purely-visual stays on **Ignore**.

## Enemy

**Mixamo Rigging**

When uploading a model to mixamo, be sure to also upload the textures.zip. Otherwise you might get an error. If error occurs, try again later.

Select CharacterBody3D

In the Scene panel toolbar, click the chain-link icon ("Instantiate Child Scene")

Browse to pistol_run.fbx, select it, confirm

Your 3D model need to replace the Mesh Instance. Then delete MeshInstance3D. Adjust transform on the .FBX/.OBJ to make it visisible. *i.e. 10.0 points.* Click the small arrow to the right on the movie icon, and create new Inhereted Scene. Locate the Animation name, and wire it in the *Ememy.gd script.* Often, it is called: *mixamo_com.*

Then use:

```gdscript
@onready var anim_player: AnimationPlayer = $"Pistol Run/AnimationPlayer"

anim_player.play("mixamo_com")
```

Then drag and drop the enemy.tscn into the main scene.

Gotcha’s: *after each change to the enemy, especially the capsule3D:*

***Re-bake the NavigationRegion3D click “<ins>bake navigation mesh</ins>” in the 3D window.***

Gotcha’s:

If enemy rotation flickers between two values near corners/close range: use atan2 + lerp_angle for facing, not look_at()/slerp - and keep NavigationAgent3D radius/height in sync with the CollisionShape3D capsule, or re-baking becomes necessary after every capsule resize.
