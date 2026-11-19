extends RefCounted

## Fixed presentation descriptions, independent of simulation or save state.
## Only private HUD callers opt into shared, immutable rows. Public projections
## retain independent mutable arrays and dictionaries by default.
static var _catalogs: Dictionary = {}


static func project(
	key: StringName,
	ids: Array[StringName],
	status_field: String,
	authority: Callable,
	shared_read_only: bool = false,
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if _catalogs.has(key):
		rows = _catalogs[key]
	else:
		for id in ids:
			var row := {"id": String(id), status_field: true, "authority": authority.call(id)}
			row.make_read_only()
			rows.append(row)
		rows.make_read_only()
		_catalogs[key] = rows
	return rows if shared_read_only else rows.duplicate(true)
