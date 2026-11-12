class_name PlanetMap
extends RefCounted

## Earth-sized mapping for a future sphere. The playable build still stands
## on a local tangent patch. These helpers wrap that patch into one finite
## circumference and turn metres into longitude and latitude. They do not
## move chunks yet. See docs/world/PLANET.md.

const RADIUS_M := 6371000.0
const CIRCUMFERENCE_M := TAU * RADIUS_M


static func wrap_component(metres: float) -> float:
	var half := CIRCUMFERENCE_M * 0.5
	return fposmod(metres + half, CIRCUMFERENCE_M) - half


static func wrap_xz(x: float, z: float) -> Vector2:
	return Vector2(wrap_component(x), wrap_component(z))


## Easting is longitude. Northing is latitude. Both are degrees.
## Latitude clamps at the poles; longitude wraps all the way around.
static func longitude_deg(east_m: float) -> float:
	return rad_to_deg(wrap_component(east_m) / RADIUS_M)


static func latitude_deg(north_m: float) -> float:
	var wrapped := wrap_component(north_m)
	var lat := clampf(wrapped / RADIUS_M, -PI * 0.5, PI * 0.5)
	return rad_to_deg(lat)


static func same_point(a: Vector2, b: Vector2) -> bool:
	var wa := wrap_xz(a.x, a.y)
	var wb := wrap_xz(b.x, b.y)
	return wa.distance_to(wb) < 0.01
