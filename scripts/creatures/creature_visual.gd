class_name CreatureVisual
extends RefCounted

## Drops an imported creature scene under VisualRoot and hides the placeholder.
## The .glb should be 1 unit = 1 metre, Y-up, origin at the feet.


static func apply_override(host: Node3D, packed: PackedScene) -> void:
	if packed == null:
		return
	var root := host.get_node_or_null("VisualRoot") as Node3D
	if root == null:
		root = host
	var visual := packed.instantiate()
	visual.name = "VisualOverride"
	root.add_child(visual)
	var placeholder := root.get_node_or_null("Placeholder")
	if placeholder is Node3D:
		(placeholder as Node3D).visible = false
