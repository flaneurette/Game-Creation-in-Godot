# Add collectibles in Godot

As example, we create a collectible gun prop.

- Create new scene, call it" "CollectGun.tscn"
- Add your 3D model of a weapon
- Add a childnode: Area3D -> CollisionShape3D -> Then select BoxShape3D

<img src="Examples/NodeListWeapon.png" />

Adjust the `Z` scale to: 5.0

it should look like this:

<img src="Examples/WeaponBox.png" />

The blue lines are the CollisionShape3D areas, which we need to let the player run into, and trigger an event:


