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

