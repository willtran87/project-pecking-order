extends RefCounted

## Lightweight authoritative layout data; querying future room bounds must not
## compile or load the complete visual builders before those rooms are needed.

const SHELL_QUALITY_LAB := Rect2(Vector2(9.05, 1.40), Vector2(11.15, 3.20) - Vector2(9.05, 1.40))
const PACKING_ANNEX := Rect2(Vector2(12.00, -8.90), Vector2(6.40, 5.80))
const RECORDS_ANNEX := Rect2(Vector2(12.00, -2.90), Vector2(6.40, 5.80))
const FARM_MUTUAL_SERVICE_COOP := Rect2(Vector2(12.00, 3.10), Vector2(6.40, 5.80))
const FARM_MUTUAL_NEGOTIATION_ROOM := Rect2(Vector2(12.00, 9.10), Vector2(6.40, 5.80))
const FARM_MUTUAL_CONTRACT_BOARD := Rect2(Vector2(-11.82, -1.66), Vector2(0.46, 3.32))
const WELLNESS_NEST := Rect2(Vector2(12.00, 15.10), Vector2(6.40, 5.80))
const TRAINING_ROOST := Rect2(Vector2(12.00, 21.10), Vector2(6.40, 5.80))
const FARMER_RELATIONS_GALLERY := Rect2(Vector2(4.10, 21.10), Vector2(6.40, 5.80))
const ROOSTER_OPERATIONS_OFFICE := Rect2(Vector2(12.00, 27.10), Vector2(6.40, 5.80))
const IT_COOP := Rect2(Vector2(12.00, 33.10), Vector2(6.40, 5.80))
const FLOCK_RELATIONS_OFFICE := Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80))
const FEED_PROCUREMENT_COOP := Rect2(Vector2(4.10, 27.10), Vector2(6.40, 5.80))
const FARMGATE_DISPATCH_DEPOT := Rect2(Vector2(18.65, -8.90), Vector2(8.80, 11.80))
