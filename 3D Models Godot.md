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

### Attach object to another object

This is mainly useful for animation, such as attaching a weapon to a right hand, inside an animation.

-  Drag your Mixamo character scene into a new scene, or double-click the FBX and choose `New Inherited Scene`. This lets you edit the imported nodes.
-  Find the `Skeleton3D` node in the scene tree.
-  Right-click Skeleton3D -> `Add Child Node -> BoneAttachment3D`.
-  Select the BoneAttachment3D and set `Bone Name` in the Inspector to the right hand, you can select where the object needs to be attached to. Like right hand, for example.
-  Drag your 3D Model, such as a weapon, `.glb` into the scene as a `child of the BoneAttachment3D`.

The object now follows the hand during the run animation.

Position it in the hand:

-  Play the run animation with the AnimationPlayer so the hand is in its typical pose.
-  Select the pistol node and adjust its `position and rotation` in the Inspector until the grip sits in the palm, with the barrel pointing forward.
-  Adjust `scale` too. Mixamo characters are often imported at 0.01 or 100x scale, so the pistol may look huge or tiny at first.
