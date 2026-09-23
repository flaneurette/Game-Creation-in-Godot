# 3D Models

A documents that documents 3D model handling in Godot.

### Adding collision detection.

This is very easy to do. Have Godot generate it on import (better for many models)

- Double-click the FBX in the FileSystem dock to open the Advanced Import Settings window.
- Select the mesh in the tree on the left.
- In the right panel, under Physics, tick Generate.
- Body Type: StaticBodyMesh
- Choose a Shape Type (Trimesh, Convex, and so on) I would suggest at first: "Automatic"
- Click Reimport.

The collision is now part of the imported scene, so every instance you place has it.

> Note: If you create a RigidBody3D, it will respond to Physics. Like a ladder will immediately fall over, unless it leans on something. A StaticBodyMesh ladder won't fall over.
