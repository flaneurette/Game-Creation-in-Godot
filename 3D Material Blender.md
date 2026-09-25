# Adding material in Blender

Material = the surface color and shininess. 

Texture = an image or pattern applied on top of it.

#### Add a basic material

- In `Object Mode`, click the part you want to color
- Open the `Material tab` in the Properties panel on the right. It's the icon at the bottom of the tab column, a red-and-white sphere.
- Click `New`. Blender creates a material with a default shader called Principled BSDF.
- Click the `Base Color` field and pick a color. 
- Set `Metallic` to about 0.8 to 1.0 and `Roughness` to about 0.3 to 0.4. Lower roughness means shinier.
- Repeat for the other parts. Click the dropdown next to the material name to reuse an existing material on another object instead of making a new one.

#### See the result

The default Solid viewport doesn't show materials well. Switch the viewport shading (the row of four sphere icons at the top right of the viewport) to `Material Preview`. Metallic surfaces look black or dull unless there's something to reflect, and Material Preview supplies that lighting. Or press `Z` and pick Material Preview from the pie menu.

#### Adding a texture (an image)

- In the Material tab, click the small dot or circle next to `Base Color`.
- Choose `Image Texture` and click `Open` to load an image file, such as a metal or wood grain photo.
- Blender needs to know how to wrap the image around the object. This is called `UV mapping`. For simple shapes, go to Edit Mode, press `A`, then `U -> Smart UV Project`.
- Check the result in Material Preview.

Alternatives to image textures:

- Use a `Noise Texture` or `Bump` node for scratches and roughness without needing an image.
- Websites like `Poly Haven` offer free PBR materials (metal, wood, leather) that you can download and plug in.
