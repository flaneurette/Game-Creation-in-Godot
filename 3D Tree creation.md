# Tree Creation in Blender

It is somewhat better to create your own trees in Blender, then to buy "all of them". Just buy a single set, perhaps 1-5 3D trees, and generate the rest yourself.

**My process:**

Buy one "Hero Tree", which is a paid tree which looks gorgeous. Behind it, place the blender generated trees. This creates a nice contrast, as the eye will land on the "Hero Tree" and assumes all the other trees are just as gorgeous. This is good for filling in large areas. The reason for this: store bought render trees are often huge in filesize: 100MB-300MB, which is too large for a game, which expects 1-5MB per tree.

### Enable the Sapling Tree Gen add-on

Sapling Tree Gen is an add-on, so it may need to be switched on first.

- `<= Blender 4.1: Edit > Preferences > Add-ons, search "Sapling" and tick the box.`
- `>= Blender 4.2: Edit > Preferences > Get Extensions, search "Sapling Tree Gen" and install it.`

### Create the tree

1. Hover your mouse over the 3D viewport and press **Shift+A**.
2. Choose Curve > Sapling Tree Gen (in some versions the entry is called "Add Tree").
3. A basic tree appears. 
4. Open the panel **"> Sapling: Add Tree"** or **"Adjust Last Operation"** panel at the bottom-lower-left of the viewport. 

> This is a small rectangular box at the lower left in the viewport. The panel only stays editable until you do something else, so tweak the tree straight away.

### Customize the tree

| Tab | What it does |
| --- | --- |
| Presets | Load ready-made trees (willow, palm, black tupelo...) and adjust from there |
| Geometry | Bevel (trunk thickness and smoothness), branch levels, scale |
| Branch Growth | How the branches spread out and curve |
| Branch Splitting | How often branches fork |
| Leaves | Tick Show Leaves, then set leaf count and shape (off by default) |

Change the seed value to get a different variation of the same tree.

### Add materials

The trunk and the leaves are separate objects, so each needs its own material.

**Bark**

1. Select the trunk, open the Material tab and click New.
2. Set the Base Color of the Principled BSDF to a dark brown.
3. Add a "Noise Texture" or a bark image texture, and connect it through a "Bump" node to the Normal input for roughness and depth.
4. Raise Roughness to around 0.8-0.9.

**Leaves**

1. Select the leaves object and add a new material.
2. Set the Base Color to green (vary it slightly for a natural look).
3. For realistic leaves, use a leaf image texture with an alpha channel, and connect its Alpha to the Principled BSDF Alpha input.
4. Optionally add a little Subsurface or Transmission so light passes through the leaves.

### Export

File > Export > Export as .FBX, .OBJ or .GLB

---

### Make a forest (scattering many trees)

**Quick method: duplicate**

- Select the tree and press Shift+D, then move it. Use Alt+D for linked duplicates that share the same mesh data.
- To vary the trees, generate a few with different seeds.

**Better method: Geometry Nodes**

1. Add a plane or your landscape mesh and open the Geometry Nodes workspace.
2. Add a "Distribute Points on Faces" node (Poisson Disk mode avoids overlapping trees).
3. Add an "Instance on Points" node and plug in your tree, either as an object via Object Info or as a collection.
4. Use the Instance on Points node's Rotation and Scale inputs, fed by Random Value nodes, to vary the trees.

**Tips**

- Lower the Sapling bevel resolution to keep the polygon count down when you have many trees.
- Convert a tree to a mesh with Object > Convert > Mesh if you need to edit it further.
- If an imported tree has a lot of vertexes, then use: Inspector > Modifier > Decimate to lower the vertexes.
- Keep a tree for a computer game small: 1-5MB
