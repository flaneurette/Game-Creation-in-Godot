# Create a 3D Model Weapon

Here we create a 3D model of a weapon with a silencer. It seems daunting, but it is fairly easy to do if you have a nice reference.

<img src="Examples/Weapon.png" />

#### Setup

-  Start a new project (General template).
-  Add a reference photo as background: `Add -> Image -> Reference`.

#### Block out the basic shapes

- Add a `cylinder` (barrel/silencer).
- Add a `cube` and elongate it (`S`, then `X`) to sit next to the cylinder.
- Add another cube as the `handgrip`.
- Add a cube, elongated, under the bullet chamber.
- Add a cube as the `finger grip`.

Tip: press `Ctrl+A -> Scale` after resizing objects so later tools behave properly.

#### Shape the finger grip

-  Switch to the `Modeling` workspace (tab at the top).
-  Select the `Poly Build` tool in the left toolbar.
-  Shape the finger grip. Do the same for the handgrip and any other parts.

#### Cut the finger grip hole

-  Select the finger grip and press `Tab` to enter `Edit Mode`.
-  Press `A` to select all.
-  Turn on `X-ray` (`Alt+Z`) so the cut reaches the hidden side.
-  Press `K` for the Knife. `Click` (don't drag) to place each point around the hole outline, and click the first point again to close the shape.
-  Press `Enter` to confirm the cut.
-  Press `3` for Face select, click inside the outlined area, and press `X -> Faces`.

The hole is now cut. If a thin plane is left behind, repeat steps 4-6 on the opposite side, or select the leftover face and delete it.

#### Finish

That's the basic model. Most of the work is placing and aligning the parts. From here you can refine it with `Bevel` (Ctrl+B), a `Subdivision Surface` modifier, and detail work.

#### Sculpt an item (optional)

Use sculpt mode when you want organic shapes, such as worn edges or a curved grip, instead of hard-edged boxes.

-  In `Object Mode`, click the item you want to sculpt (for example the handgrip).
-  Press `Ctrl+A -> Scale` to apply its scale, so brushes behave evenly.
-  `Add more geometry.` A default cube has only 8 vertices, so there is nothing to sculpt. Open the `Modifiers` tab (wrench icon), choose `Add Modifier -> Generate -> Multiresolution`, and click `Subdivide` 4 to 5 times.
   - Use `Simple` instead of Subdivide if you want to keep the box shape. Regular Subdivide rounds it off into a blob.
-  Switch modes: use the `mode dropdown` at the top-left of the viewport and select `Sculpt Mode`, or press `Ctrl+Tab` and pick Sculpt Mode from the pie menu.
-  Choose a brush from the left toolbar: `Draw` (push out), `Clay Strips` (build up), `Grab` (move large areas), or `Smooth` (clean up bumps).
-  Paint on the item. Hold `Ctrl` while drawing to push the surface in instead of out, which works well for finger grooves. Use `F` to change brush size and `Shift+F` to change strength.
- When you're done, switch back to `Object Mode` using the same dropdown.

`Tip:` Sculpt each part separately. Sculpting works on one object at a time, so select the item first, then switch modes.

#### Export the pistol from Blender

-  Save a copy
-  Save current as `Weapon_Export.blend`
-  Delete the camera node.
-  Apply scale first: `Ctrl+A -> Scale` in Object Mode.
-  Join the parts (select them all, `Ctrl+J`) or parent them to one object, so you get a single pistol.
-  Go to `File -> Export -> glTF - 0 (.glb/.gltf)` and save it inside your Godot project folder.

# In Godot

#### Attach it in Godot

-  Drag your Mixamo character scene into a new scene, or double-click the FBX and choose `New Inherited Scene`. This lets you edit the imported nodes.
-  Find the `Skeleton3D` node in the scene tree.
-  Right-click Skeleton3D -> `Add Child Node -> BoneAttachment3D`.
-  Select the BoneAttachment3D and set `Bone Name` in the Inspector to the right hand, you can select where the object needs to be attached to. Like right hand, for example.
-  Drag your pistol `.glb` into the scene as a `child of the BoneAttachment3D`.

The pistol now follows the hand during the run animation.

#### Position it in the hand

-  Play the run animation with the AnimationPlayer so the hand is in its typical pose.
-  Select the pistol node and adjust its `position and rotation` in the Inspector until the grip sits in the palm, with the barrel pointing forward.
-  Adjust `scale` too. Mixamo characters are often imported at 0.01 or 100x scale, so the pistol may look huge or tiny at first.

#### Tips

- `Pivot point:` in Blender, place the pistol's origin at the handgrip (`Object -> Set Origin`, or move the 3D cursor there first). This makes fitting it to the hand much easier in Godot.
- `Left hand:` Mixamo pistol animations often have the second hand supporting the gun. It won't grip on its own, so use the pose from the animation, or add IK later if you want it exact.
- `Swapping weapons:` since the pistol is just a child of the BoneAttachment3D, you can show, hide, or replace it in code.

