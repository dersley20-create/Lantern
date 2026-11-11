class_name BiomeIds
extends Object

## Ids shared by biome resources and the surface classifier.
## The Underhollows are reserved for a future underground layer and are never
## returned for the walkable surface.

const HEARTHVALE: StringName = &"hearthvale"
const GLIMMERWOOD: StringName = &"glimmerwood"
const SALTGLASS: StringName = &"saltglass"
const CLOUDLOFT: StringName = &"cloudloft"
const GREYING: StringName = &"greying"
const UNDERHOLLOWS: StringName = &"underhollows"


static func surface() -> Array[StringName]:
	return [HEARTHVALE, GLIMMERWOOD, SALTGLASS, CLOUDLOFT, GREYING]
