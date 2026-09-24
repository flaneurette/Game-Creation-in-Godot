# Create a 3D Model Weapon

Here we create a 3D model of a weapon with a silencer. It seems daunting, but it is fairly easy to do if you have a nice reference.

<img src="Examples/Weapon.png" />

#### Setup

1. Start a new project (General template).
2. Add a reference photo as background: `Add -> Image -> Reference`.

#### Block out the basic shapes

- Add a `cylinder` (barrel/silencer).
- Add a `cube` and elongate it (`S`, then `X`) to sit next to the cylinder.
- Add another cube as the `handgrip`.
- Add a cube, elongated, under the bullet chamber.
- Add a cube as the `finger grip`.

Tip: press `Ctrl+A -> Scale` after resizing objects so later tools behave properly.

#### Shape the finger grip

1. Switch to the `Modeling` workspace (tab at the top).
2. Select the `Poly Build` tool in the left toolbar.
3. Shape the finger grip. Do the same for the handgrip and any other parts.

#### Cut the finger grip hole

1. Select the finger grip and press `Tab` to enter `Edit Mode`.
2. Press `A` to select all.
3. Turn on `X-ray` (`Alt+Z`) so the cut reaches the hidden side.
4. Press `K` for the Knife. `Click` (don't drag) to place each point around the hole outline, and click the first point again to close the shape.
5. Press `Enter` to confirm the cut.
6. Press `3` for Face select, click inside the outlined area, and press `X -> Faces`.

The hole is now cut. If a thin plane is left behind, repeat steps 4-6 on the opposite side, or select the leftover face and delete it.

#### Finish

That's the basic model. Most of the work is placing and aligning the parts. From here you can refine it with `Bevel` (Ctrl+B), a `Subdivision Surface` modifier, and detail work.

#### Sculpt an item (optional)

Use sculpt mode when you want organic shapes, such as worn edges or a curved grip, instead of hard-edged boxes.

1. In `Object Mode`, click the item you want to sculpt (for example the handgrip).
2. Press `Ctrl+A -> Scale` to apply its scale, so brushes behave evenly.
3. `Add more geometry.` A default cube has only 8 vertices, so there is nothing to sculpt. Open the `Modifiers` tab (wrench icon), choose `Add Modifier -> Generate -> Multiresolution`, and click `Subdivide` 4 to 5 times.
   - Use `Simple` instead of Subdivide if you want to keep the box shape. Regular Subdivide rounds it off into a blob.
4. Switch modes: use the `mode dropdown` at the top-left of the viewport and select `Sculpt Mode`, or press `Ctrl+Tab` and pick Sculpt Mode from the pie menu.
5. Choose a brush from the left toolbar: `Draw` (push out), `Clay Strips` (build up), `Grab` (move large areas), or `Smooth` (clean up bumps).
6. Paint on the item. Hold `Ctrl` while drawing to push the surface in instead of out, which works well for finger grooves. Use `F` to change brush size and `Shift+F` to change strength.
7. When you're done, switch back to `Object Mode` using the same dropdown.

`Tip:` Sculpt each part separately. Sculpting works on one object at a time, so select the item first, then switch modes.

Yes, and it's easy in Godot. You attach the pistol to the hand bone so it follows the animation.

#### Export the pistol from Blender

1. Apply scale first: `Ctrl+A -> Scale` in Object Mode.
2. Join the parts (select them all, `Ctrl+J`) or parent them to one object, so you get a single pistol.
3. Go to `File -> Export -> glTF 2.0 (.glb/.gltf)` and save it inside your Godot project folder.

# In Godot

#### Attach it in Godot

1. Drag your Mixamo character scene into a new scene, or double-click the FBX and choose `New Inherited Scene`. This lets you edit the imported nodes.
2. Find the `Skeleton3D` node in the scene tree.
3. Right-click Skeleton3D -> `Add Child Node -> BoneAttachment3D`.
4. Select the BoneAttachment3D and set `Bone Name` in the Inspector to the right hand, you can select where the object needs to be attached to. Like right hand, for example.
5. Drag your pistol `.glb` into the scene as a `child of the BoneAttachment3D`.

The pistol now follows the hand during the run animation.

#### Position it in the hand

1. Play the run animation with the AnimationPlayer so the hand is in its typical pose.
2. Select the pistol node and adjust its `position and rotation` in the Inspector until the grip sits in the palm, with the barrel pointing forward.
3. Adjust `scale` too. Mixamo characters are often imported at 0.01 or 100x scale, so the pistol may look huge or tiny at first.

#### Tips

- `Pivot point:` in Blender, place the pistol's origin at the handgrip (`Object -> Set Origin`, or move the 3D cursor there first). This makes fitting it to the hand much easier in Godot.
- `Left hand:` Mixamo pistol animations often have the second hand supporting the gun. It won't grip on its own, so use the pose from the animation, or add IK later if you want it exact.
- `Swapping weapons:` since the pistol is just a child of the BoneAttachment3D, you can show, hide, or replace it in code.

