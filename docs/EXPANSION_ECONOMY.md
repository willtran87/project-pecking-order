# Office Expansion & Economy

Pecking Order treats capital spending as a visible change to the workplace, not a passive percentage in a menu. Every facility should answer four questions before it enters the catalog:

1. What new object or room appears in the office?
2. What recurring obligation does it add?
3. Which measurable production behavior does it change?
4. What satirical pressure or downside follows the benefit?

The Feed Fund protects feed, payroll, facility upkeep, wage arrears, signed breach exposure, and filed Treasury liabilities before capital is considered spendable. A purchase therefore cannot create an expansion whose first operating bill is already unfunded. If the Farm Treasury has liabilities and no remaining credit headroom, capital is frozen until the office restores room on the line.

## Farm Treasury: a conserving shift-close journal

DepartmentSimulation schema v24 retains the strict v23 `farm_treasury_state` beside the operating and campus ledgers and adds an independently persisted case-docket incident stream. Schema-v22 Treasury migration remains deliberately neutral: it preserves only the checkpoint's real Feed Fund and completed-day chronology, and invents no principal, invoice, interest, rating, or receipt history. Authentic v23 saves enter the legacy `PO-1701` docket without changing their active decision or economy. Current restore replays the retained journal and validates the bounded incident bag before committing, rejecting unknown cases, duplicates, altered cents, broken chronology, or a receipt whose math cannot be reproduced.

Every close categorizes real production and settlement inflows separately from feed, facilities, campus services, portfolio upkeep, Farmgate shortfalls, and other vendor obligations. The receipt must satisfy this equality to the cent:

```text
opening cash + categorized inflow + credit draw
= interest paid + vendors paid + labor paid + principal repaid + closing cash
```

Cash and automatic credit share the same first priorities: carried interest, carried vendor invoices, current interest, then current vendors. Remaining cash pays current and carried wages, then repays principal. Credit is never allowed to pay labor; an uncovered wage remains in the existing wage-arrears ledger instead of being disguised as a vendor draw. Interest is charged only on principal present at the opening of the close, so a new draw starts accruing on the following shift.

The starting line is $50 plus $5 per Farm Mutual standing point, capped at $150 before ratings. Three profitable, debt-free closes advance the rating from **Field File** to **Steady Ledger**, then **Prime Roost**. Each tier adds $25 of line capacity and reduces the 5% per-shift rate by one percentage point, producing a $200 absolute maximum line and a 3% prime rate. The minimum nonzero interest charge is $1. Flockwatch exposes rating, principal/line, headroom, rate, wage arrears, vendor arrears, and interest arrears; Farmer Review preserves the complete close receipt. These are operating bridges, not free capital: every liability joins the protected reserve, and an exhausted indebted line blocks expansion.

## Implemented vertical slice: Candling & Rework Bay

The first capital facility is unlocked by the Day-2 Shell Quality Checks milestone and commissioned during shift review.

| Term | Value |
|---|---:|
| Capital cost | $40.00 |
| Daily maintenance | $3.00 |
| Office-wide crack risk | -1.5 percentage points |
| Rework processing speed | +20% |
| Maximum level | 1 |

Before purchase, the east service alcove contains a taped utility pad. Purchase replaces it with a connected QA bench, enclosed candling hood, thickness gauge, calibration weights, paperwork tray, terminal, status lamps, and a host-mounted enamel plate. The module publishes its footprint to the route test, contains no fake eggs, adds no runtime collisions, and stays below the sightline to the right-hand desks.

The complete transaction is authoritative and persistent:

- milestone, review phase, affordability, unknown ID, and duplicate requests are checked atomically;
- $40 is debited once while the new $3 daily obligation remains protected;
- ownership, effects, and maintenance survive current simulation schema-v23 save/restore;
- the Flockwatch card shows capital, upkeep, effects, projected spendable cash, and the exact disabled reason;
- the farmer review itemizes production credit, bonuses, feed, payroll, facilities, net operating result, closing Feed Fund, and wage arrears.

## Implemented expansion: Farmer Brand Packing Annex

After two completed shifts, the unused parcel beyond the office's open east edge changes from a board-held lease outline into a surveyed construction site. This unlock is independent of the mutually exclusive probation specialization, so every campaign can choose whether and when to build it.

| Tier | Capital | Total daily upkeep | Visible construction | Economic effect |
|---|---:|---:|---|---|
| Level 1 | $60.00 | $3.00 | Connected slab and shell, manual conveyor, carton rack, label printer, status tower, six-slot contract meter | +4% sound/golden graded value; each six-good-egg carton pays $3 |
| Level 2 | $95.00 | $5.00 | Automated sealer, second belt, weighing head, branded pallet | +8% value; each carton pays $6 |
| Level 3 | $140.00 | $8.00 | Premium dispatch board, contract vault, loading hatch, pallet jack | +12% value; each carton pays $9 |

The annex occupies a declared `6.4m × 5.8m` external footprint beginning at `x = 12`, beyond every chicken route and without reducing the existing 24×18-meter office circulation. The camera overview widens to include the lease parcel; each accepted purchase briefly focuses the new room. Tiers are cumulative rather than replacements, so later purchases retain earlier equipment and make the facility visibly busier.

Only authoritative sound or golden output advances the contract meter. A cracked egg receives no packing premium and fills no slot. The sixth qualifying egg closes the carton, briefly lights all six physical slots, and carries the exact tier-scaled settlement in its economic receipt. Carton progress, tier, lifetime payouts, daily payouts, and maintenance survive current simulation schema-v23 JSON save/restore; schema-v8 files migrate with an unowned annex and zero invented output.

Capital preflight protects the *change* in upkeep at each tier: $3 for level one, $2 more for level two, and $3 more for level three. A purchase one cent below capital plus that revised reserve rejects atomically. The same formula now protects the $2 daily workstation overhead for capacity and the exact added feed plus wage burden for every hire.

## Implemented expansion: Laying Records Annex

After two completed shifts, the east-central records parcel becomes available beside the existing archive and copier service. The room turns intake capacity into a visible, investable production constraint.

| Tier | Capital | Total daily upkeep | Live-file capacity | Visible construction |
|---|---:|---:|---:|---|
| Level 1: Rolling Records Floor | $70.00 | $4.00 | 18 → 24 | Connected slab, rolling shelf banks, transfer cart, folder slots, and mechanical file counter |
| Level 2: Pneumatic Triage | $105.00 | $7.00 | 24 → 30 | Lane-colored intake chutes, powered sorting spine, carriage rails, and additional shelving |
| Level 3: Permanent Retention Vault | $155.00 | $11.00 | 30 → 36 | Compact archive vault, retention hardware, overdue beacon, and overflow intake bin |

Arrivals are rolled even when every live-file slot is occupied. A full archive records the rejected file and its lane's estimated base value in daily and lifetime missed-intake ledgers. That value is opportunity cost only: it never enters the Feed Fund because no hen accepted, processed, laid, graded, or presented the work.

The tradeoff is deliberately uncomfortable. More shelves retain demand that would otherwise leave the farm, but storage does not create throughput. An understaffed or poorly routed flock can convert the larger book into more overdue work, lower campaign scores, and higher daily maintenance. The physical room makes that debt readable: folders match authoritative outstanding files and lane colors, the counter shows occupancy versus capacity, rejected files collect in the overflow bin, and overdue work powers the warning beacon.

The Annex occupies its own declared `6.4m × 5.8m` east parcel, keeps the copier-aligned transfer strip clear, stays outside every chicken route, and reveals all three tiers cumulatively. Schema-v10 saves migrate to schema v11 with an unowned Records Annex and zero invented rejection history.

## Implemented demand system: Farm Mutual Contract Board

After two completed shifts, Day-3 closed-shift planning opens the Farm Mutual Contract Board. Management must either sign exactly one next-shift binder or explicitly file the **standard book**, which declines outside work for that day without a hidden penalty. A binder can be signed only when its total capacity gate, required empty file slots, and full breach reserve all pass preflight.

| Binder | Capacity / empty slots | Authored folder arrivals and deadlines | Fulfillment | Premium | Breach |
|---|---:|---|---:|---:|---:|
| Homestead Stability Binder | 18 / 5 | 9:00 AM: 3 Nest Damage + 1 Predator Loss, due 11:00 AM; 11:00 AM rush: 1 Nest Damage, due 1:00 PM | 4 of 5 | $10.00 | $5.00 |
| Predator Watch Pool | 24 / 6 | 9:00 AM: 3 Predator Loss + 1 Nest Damage, due noon; noon rush: 2 Predator Loss, due 3:00 PM | 5 of 6 | $16.00 | $8.00 |
| Exceptions Retention Covenant | 30 / 6 | 9:00 AM: 2 Appeals + 1 Predator Loss + 1 Nest Damage, due 1:00 PM; 1:00 PM rush: 2 Appeals, due 5:00 PM | 5 of 6 | $24.00 | $12.00 |

Only sound or golden folders completed inside their disclosed service windows count toward fulfillment; cracked or late work never qualifies. Signing does not debit cash or award income. It assigns stable claim IDs, reserves every contract folder against live-file capacity, and protects the exact breach amount from later discretionary spending. The scheduled batches then enter their real lane queues at the stated times, marked **Mutual Binder** or **Contract Rush**, without pausing production or opening an incident modal. Closing review credits the full premium on success or debits the full breach once on failure, with both kept separate from ordinary flock production.

The capacity ladder gives the Records Annex a market purpose: the base 18-file archive can take Homestead, level one at 24 files opens Predator Watch, and level two at 30 files opens Exceptions Retention. Contract planning, scheduled folders, decline receipts, fulfillment ledgers, and settlement receipts survive strict simulation schema-v23 JSON save/restore; legacy schema-v11 saves migrate with no invented contract.

The office mirrors this state on a shallow physical board in the center bay of the left wall. Locked shutters open into three kraft client folders with lane tokens, rush tags, premium coins, an active binder clip, and persistent **Mutual Paid** or **Term Breached** stamps. During the responsive planning view, `1`-`3` selects a folder, `Enter` signs the fully disclosed terms, `D` files the standard book, and `C` continues only after either choice has an authoritative receipt.

## Implemented expansion: Farm Mutual Service Coop

Farm Mutual standing is not a second spendable currency. It is derived from the exact settled contract ledgers:

```text
standing = max(0, 2 × fulfilled binders − breached binders)
```

Unlisted standing begins at 0; Bronze begins at 2, Silver at 6, and Gold at 12. A fulfilled binder adds two standing points and extends both the current and best clean-binder streak. A breach subtracts one point, resets the current clean streak, and places only that same binder on cooldown for the next planning day; the other authored binders remain available if their normal preflights pass. Filing the standard book changes neither standing nor the clean streak.

Standing combines with the office's real supply constraints to gate a cumulative northeast facility:

| Tier | Standing | Live-file capacity | Active hens | Capital | Total daily upkeep | Fulfilled-binder bonus | Visible construction |
|---|---:|---:|---:|---:|---:|---:|---|
| Level 1: Bronze Client Seal Desk | 2 | 24 | 4 | $75.00 | $3.00 | +50% of authored base premium | Service counter, Bronze seal press, standing certificate case, and empty binder pigeonholes |
| Level 2: Silver Timed Dispatch Hutch | 6 | 30 | 5 | $120.00 | $6.00 | +100% of authored base premium | Retains Bronze; adds three lane dispatch tubes, stamped packet slots, courier cage, and rush beacon |
| Level 3: Gold Account Gallery | 12 | 36 | 6 | $180.00 | $9.00 | +150% of authored base premium | Retains Bronze and Silver; adds Gold Seal arch, contract vault, twelve-segment standing totem, result hardware, and attribution backdrop |

All gates apply to the *next* purchase. A completed tier is permanent: later breaches may lower standing and prevent a further upgrade, but they never demolish or demote paid construction. Capacity and active-hen requirements can likewise block a future tier without invalidating one already owned. Capital preflight still protects the revised total upkeep together with feed, payroll, workstation overhead, wage arrears, and any signed breach reserve.

The premium benefit settles only from authoritative fulfillment. At signing, the simulation freezes the installed Service Coop level and calculates an additive bonus against the authored base premium—never against a prior tier's total. The folder, signed receipt, active binder, save checkpoint, and closing result carry the same exact integer-cent `base + Service Coop bonus = total` breakdown. A later Coop purchase cannot rewrite an active binder, while a breached binder receives no bonus at all. This keeps the joke legible: public confidence makes successful work more valuable, but the flock still has to deliver every qualifying folder.

The visual-only Coop occupies the declared `6.4m × 5.8m` northeast parcel beginning at `x = 12`, separated from the Records Annex by a 20-centimeter service seam and outside authored chicken routes. Before Bronze, a standing-gated boundary becomes a surveyed parcel without implying ownership. Purchases reveal each tier cumulatively. The room then mirrors—without inventing—authoritative standing segments, active clean packets, rush state, fulfilled bonus credit, and breach shutter state.

Schema v13 adds the Service Coop, clean-streak ledgers, frozen contract bonus fields, and standing receipts. Schema-v12 saves migrate with an unowned Coop, zero invented bonus, and standing derived from their real fulfillment and breach totals.

## Implemented market layer: seasons and negotiated riders

Day 6 begins a deterministic Farm Mutual market calendar. Each season lasts three planning days, then advances through Spring, Summer, Autumn, and Winter before starting a new market year. The same campaign day always produces the same season; there is no random reroll to exploit by reloading.

| Season | Nest Damage demand | Predator Loss demand | Appeals demand | Market pressure |
|---|---:|---:|---:|---|
| Spring Hatch Surge | +20% | 0% | -10% | Routine hatch and nest losses dominate the book |
| Summer Predator Migration | -5% | +25% | +5% | Fox and hawk migration makes predator work expensive |
| Autumn Retention Audit | -10% | +5% | +30% | Renewal appeals become the richest, most exposed lane |
| Winter Feed-Fund Squeeze | +10% | +10% | +10% | Every lane rises while farm reserves tighten |

Each binder's seasonal demand is the integer, half-up weighted average of those percentages across its authored folder mix. The resulting premium delta applies to the authored base premium. Positive seasonal pressure also raises the authored breach at half that rate; favorable negative demand can reduce the premium, but never creates a negative breach surcharge.

Gold-standing bureaus can turn that market pressure into a visible capital decision by commissioning the Farm Mutual Negotiation Room:

| Term | Value |
|---|---:|
| Unlock | Day 6, Gold standing (12), and Service Coop level 3 |
| Capital cost | $240.00 |
| Daily upkeep | $12.00 |
| Capacity | One optional rider per signed binder |

The purchase is permanent even if a later breach lowers standing. Before purchase, the north parcel remains a surveyed prospect; afterward it becomes a reeded-glass underwriting pavilion with a walnut-and-felt table, six chicken chairs, an intentionally oversized empty farmer-credit chair, a signing press, and authoritative contract folios. The room sits outside the worker navigation and collision envelope, so its footprint does not obstruct the existing office routes.

| Rider | Premium change | Breach change | Operational term |
|---|---:|---:|---|
| Standard Terms | 0% | 0% | Keep the seasonal binder exactly as quoted |
| Expedited Hatch Rider | +25% | +50% | Shorten every service window by 60 minutes, to a 60-minute minimum, and mark one additional non-rush folder as rush work |
| Specialist Roost Endorsement | +35% | +25% | Convert every scheduled folder to the binder's authored dominant lane |
| Rested Flock Warranty | +40% | +40% | Add a settlement safeguard requiring flock welfare of at least 72 |

Terms are additive and disclosed before signature:

```text
fulfilled premium = authored base + seasonal delta + rider delta + Service Coop bonus
breach liability = authored breach + seasonal delta + rider delta
```

The Service Coop bonus continues to use only the authored base, so neither season nor rider compounds it. Selecting a rider creates no cash movement or liability; only signing freezes the exact season, rider, folder schedule, premium, breach reserve, room level, and welfare gate into the binder. A later market turn or facility purchase cannot rewrite those terms. Schema v14 adds the room and the frozen seasonal/rider breakdown; schema-v13 saves migrate with no room and with existing binders preserved as neutral Standard Terms.

## Implemented flock-care campus: Wellness Nest and Training Roost

Flock care changes real chicken state before it changes a score. The Wellness Nest never adds a flat welfare modifier and cannot manufacture a Rested Flock settlement. Instead, its cumulative tiers reduce fatigue and stress as work happens, improve recovery during actual BREAK state, add a small morale recovery only while a hen is really resting, and improve the same overnight recovery applied to every active worker.

| Wellness tier | Day / desks / active hens | Capital | Total upkeep | Work strain | Break recovery | Overnight fatigue / stress | Satirical pressure |
|---|---:|---:|---:|---:|---:|---:|---|
| Level 1: Quiet Nest Cubbies | 3 / 4 / 4 | $70.00 | $5.00 | 92% | 115% | 27 / 12 | Next clutch target +1 |
| Level 2: Rotating Recovery Room | 6 / 5 / 5 | $115.00 | $9.00 | 84% | 130% | 30 / 14 | Next clutch target +1 |
| Level 3: Rested Flock Suite | 9 / 6 / 6 | $175.00 | $14.00 | 76% | 150% | 34 / 17 | Next clutch target +1 |

The quota increase occurs once at each accepted purchase and is included in the authoritative receipt. This makes the joke causal: management funds care, measures the recovery, then immediately books the recovered capacity. Upkeep and the larger target remain visible beside the welfare benefit, so the room is neither a free buff nor decorative square footage.

The Training Roost is a matching three-tier credential economy. Each tier requires the corresponding Wellness Nest tier, the same desk and active-hen ladder, and at least one employed hen at career level one, two, or three. The facility changes the exact sponsorship terms shown in Senior Review and the worker dossier; UI layers do not recompute or hardcode them.

| Training tier | Day / Wellness / career | Capital | Total upkeep | Sponsorship | Training work pace | Coaching XP bonus |
|---|---:|---:|---:|---:|---:|---:|
| Level 1: Practice Terminal | 4 / 1 / 1 | $85.00 | $6.00 | $10.00 | 90% | +2 |
| Level 2: Cross-Lane Classroom | 7 / 2 / 2 | $135.00 | $10.00 | $8.00 | 95% | +4 |
| Level 3: Credential Gallery | 10 / 3 / 3 | $210.00 | $16.00 | $6.00 | 100% | +6 |

Accreditation still adds $1 to that hen's permanent daily wage. The capital and upkeep make training cheaper and less disruptive, but a successful program grows payroll instead of erasing it. Both facilities publish one nested `flock_care` snapshot containing current welfare versus the 72-point Rested Flock gate, real recovery terms, active breaks and training files, exact sponsorship terms, and the next useful care investment.

The two rooms extend the east campus in stable `6.4m × 5.8m` parcels with 20-centimeter service seams. Wellness begins at `z = 15.1`; Training begins at `z = 21.1`. Locked surveys become cumulative cutaway rooms, with recovery cubbies, water/feed service, practice terminals, manuals, and a credential rail driven from authoritative ownership and flock state. They contain no collision or navigation geometry and remain outside every authored chicken route. Schema v15 adds both facility keys through a neutral schema-v14 migration; the Training Roost's matching Wellness dependency remains a strict structural save invariant.

## Implemented operations campus: Rooster Operations Office and IT Coop

Operations turns management span and automation into explicit capital liabilities instead of invisible global bonuses. The Rooster Operations Office expands the number of consequential hen check-ins that can be filed in one day, while every installed tier also adds separate supervisor payroll and an exact once-per-shift surveillance burden to the employed flock.

Those supervisor liabilities are now people rather than an abstract tier bonus. A new department begins with Cornelius Claimwell; each Rooster Office tier funds one additional named post, up to four managers. The default roster covers Credit, Quota, Compliance, and Culture doctrines. A review-time successor slate also exposes Reorg and Automation candidates. Appointing one pays a disclosed signing cost and replaces the newest post without silently increasing headcount or the post's base salary.

| Rooster tier | Day / desks / active hens | Capital | Room upkeep | Supervisor payroll | Check-ins per day | Stress / grievance per hen / flock solidarity |
|---|---:|---:|---:|---:|---:|---:|
| Level 1: Shift Board Perch | 5 / 4 / 4 | $100.00 | $4.00 | $5.00 | 2 | 0.50 / 0.75 / 0.50 |
| Level 2: Glass Supervision Pod | 8 / 5 / 5 | $160.00 | $7.00 | $8.00 | 3 | 1.00 / 1.25 / 1.00 |
| Level 3: Command Roost Gallery | 11 / 6 / 6 | $240.00 | $11.00 | $12.00 | 4 | 1.50 / 2.00 / 1.50 |

Each hen remains limited to one check-in per day. The extra capacity can therefore distribute credit or coaching across more of the flock, or spread quota pressure more widely; it cannot repeatedly farm one worker for benefits. Surveillance applies exactly once with the morning directive and cannot be duplicated by saving and restoring mid-shift.

Every rooster has a team assignment (whole flock, front roost, back roost, AUTO desk, or the current at-risk file) and a filed posture (coach, protect shells, chase quota, audit, visibility, or alignment meetings). A posture does nothing until the player files it during review; after that it settles with the morning directive and feeds the authoritative work, crack-risk, trust, grievance, stress, compliance, and farmer-favor calculations. Overlapping quota and quality or coaching and audit instructions create visible conflicts. More than one manager per two active hens creates management-density meeting drag whether or not the reports sound productive.

Managers file reports, visibility points, interventions, and credit claims; they always produce zero eggs. Influence grows from the sound eggs they supervise and quota success. Thresholds promote them from Acting Lead through Assistant Roost Supervisor, Senior Clutch Manager, Executive Vice Rooster, and Chief Egg Officer. Every promotion adds $1.00 to daily supervisor payroll. When a quota is missed, quota-, audit-, or visibility-oriented managers may place the lowest-output assigned hen on a PIP, transferring failure downward as trust loss and grievance.

The IT Coop work bonus assists only hens who are really employed, seated, working, and assigned to AUTO. Manual routing always overrides it. Level one also lets AUTO recognize an earned secondary credential, while higher tiers narrow the specialty-versus-deadline grace window and add a modest real peckwork multiplier. Each tier requires the matching Records Annex and Rooster Office tier plus four/five/six authorized desks and active hens.

| IT tier | Day / matching Records + Rooster | Capital | Total upkeep | AUTO pace | Specialty grace | Compliance exposure | Ledger Molt patch |
|---|---:|---:|---:|---:|---:|---:|---:|
| Level 1: Cable & Repair Bench | 6 / 1 | $130.00 | $10.00 | 103% | 150 min | 1.0 | $22.00 |
| Level 2: Predictive Dispatch Rack | 9 / 2 | $200.00 | $17.00 | 106% | 120 min | 1.8 | $26.00 |
| Level 3: Automated Claims Sorter | 12 / 3 | $300.00 | $26.00 | 110% | 60 min | 2.8 | $30.00 |

Automation never creates a file, advances an empty chair, bypasses laying or grading, or credits a farmer delivery. Its recurring compliance exposure and escalating spreadsheet-failure penalties make the benefit a disclosed risk surface rather than free throughput. AUTO remains an opt-in assignment on each employed hen; there is no separate selectable automation protocol.

Both rooms occupy cumulative 6.4 by 5.8 meter cutaway parcels north of Training, joined by a second circulation spine that exactly continues the care campus. Rooster stations and IT cabinets accumulate one/two/three by tier. Funded managers also appear as distinct imported chicken bodies with doctrine colors, professional accessories, report folders, and separate patrol tracks in the management aisle. Permanent identities use modeled architectural type; changing assignments, pressure, speed, and incident costs appear only on physical boards, screens, tags, or invoice clips. Locked parcel notices remain subordinate close-reading fixtures. DepartmentSimulation schema v16 originally appended both operations keys through a neutral strict v15 migration and preserved purchased tiers after later staff loss; current schema v25 adds the roster with a neutral v24 migration that creates one named record for every already-funded post. The outer composite campaign-save envelope remains schema v2.

The authoritative `operations` projection is version 2 and has a frozen presentation contract:

- top level: the original version-one fields plus `manager_roster`, `manager_candidates`, `manager_capacity`, `manager_assignments`, `manager_postures`, `management_density`, `management_reports`, and `last_manager_action`;
- `supervision`: `action_limit`, `actions_used`, `actions_remaining`, every accepted action receipt, separate supervisor payroll, the three surveillance millipoint values, quota-pressure count, and whether shift pressure has settled;
- `automation`: enabled state, work basis points/multiplier, specialty grace, secondary-specialty recognition, compliance exposure, Ledger Molt patch and spreadsheet penalties, AUTO-enrolled/active-file counts, and whether shift exposure has settled;
- `daily_costs`: separate supervisor payroll, Rooster maintenance, and IT maintenance. The next-action record separates maintenance, supervisor-payroll, and total added daily operating cost; the main snapshot also separates daily hen and supervisor payroll.

Flockwatch reads this projection directly: its inline **Rooster Operations** block shows allowance use, remaining actions, payroll, pressure, density, meeting burden, conflicts, reports, and compact roster controls. The successor slate stays in this existing scroll surface rather than opening another permanent menu. The Rooster and IT facility cards show current-to-next deltas without replacing the existing focus or scroll position. A selected employed AUTO hen's dossier shows real IT support; an applicant shows none, and any manual tray is labeled as an explicit override.

Focused verification:

```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . --script tests/operations_economy_test.gd
& $godot --headless --path . --script tests/operations_persistence_test.gd
& $godot --headless --path . --script tests/manager_roster_economy_test.gd
& $godot --headless --path . --script tests/manager_roster_presentation_test.gd
& $godot --headless --path . --script tests/facilities_ui_test.gd
& $godot --headless --path . --script tests/claim_routing_ui_test.gd
& $godot --headless --path . --script tests/rooster_operations_office_visual_test.gd
& $godot --headless --path . --script tests/it_coop_visual_test.gd
```

For authored level-three captures, `--capture-rooster-operations-office`, `--capture-it-coop`, and `--capture-operations-campus` write `captures/rooster_operations_office_level3.png`, `captures/it_coop_level3.png`, and `captures/operations_campus.png`, respectively.

## Flock Relations Office: labor cases as an operating liability

Flock Relations converts the human cost already created by wages, surveillance, automation, credit allocation, and overwork into named workplace cases. It is not a passive welfare bonus. The room creates a new review-time decision loop: leave a case open and carry compliance, solidarity, and grievance pressure into the next closing; fund a remedy; mediate; file a coercive PIP; or, at the final tier, force binding arbitration.

Each tier requires the matching Rooster Operations Office and Wellness Nest tier. Management authority therefore cannot outrun either its supervision infrastructure or its physical remedy capacity.

| Flock Relations tier | Day / matching Rooster + Wellness | Capital | Total upkeep | Open case slots | Review authorizations |
|---|---:|---:|---:|---:|---:|
| Level 1: Open-Nest Case Intake | 7 / 1 | $110.00 | $5.00 | 1 | 1 |
| Level 2: Mediation & PIP Room | 10 / 2 | $175.00 | $9.00 | 2 | 2 |
| Level 3: Mandatory Arbitration Roost | 13 / 3 | $260.00 | $15.00 | 3 | 3 |

At closing, the simulation may file at most one case when a real employed hen's documented risk reaches 160. Risk uses the worker's grievance, stress, fatigue, manager trust, any outstanding wage arrears, and low-compliance IT exposure; it never rolls a random grievance into existence. The highest-risk eligible hen files first, with worker ID breaking a tie. A worker cannot hold two open cases at once and the room cannot exceed its installed case capacity.

Cases are categorized from stored evidence in this order: deferred-pay dispute, automation appeal, supervision-and-surveillance grievance, occupational nest strain, work-product credit claim, then general workplace grievance. Severity is one at risk 160–219, two at 220–279, and three at 280 or above. Every unresolved case carried across a later closing applies exactly one further consequence: coop obedience −1.5, flock unity +1.5, and the named hen's grievance +2.

| Review disposition | Required tier | Feed Fund cost | Named-hen / office consequence |
|---|---:|---:|---|
| Fund Remedy | 1 | $8 + $4 × severity | Trust +12, grievance −16, stress −8, obedience +4, farmer favor −2 |
| Mediate | 2 | $4 + $2 × severity | Trust +7, grievance −9, stress −4, obedience +2, farmer favor −1 |
| File PIP | 1 | $0 | Trust −10, grievance +14, stress +8, obedience −3, unity +4, farmer favor +3 |
| Binding Arbitration | 3 | $6 + $3 × severity | Trust −3, grievance −5, stress −3, obedience +6, unity +2, farmer favor +1 |

Rejected resolutions are atomic: an unknown or closed case, unavailable tier, active-shift attempt, exhausted review allowance, or one-cent Feed Fund shortfall cannot change money, relationships, counters, or history. Accepted dispositions debit exact integer cents, publish a before/after receipt, remove the open case, update bounded history, and refresh both Flockwatch and the physical room.

The authoritative `flock_relations` projection has ten top-level keys: `level`, `capacity`, `resolution_limit`, `resolutions_used_today`, `open_case_count`, `open_cases`, `resolved_total`, `denied_total`, `settlement_spend_total_cents`, and `last_resolution`. Each public case retains its integer identity and evidence while adding a stable farm docket label, a factual evidence summary, and authoritative action options. Flockwatch does not reconstruct prices or consequences; physical folders, case tokens, outcome lamps, and settlement props appear only from this projection.

The 6.4 by 5.8 meter west-side office mirrors IT across the north governance spine. Its cumulative construction progresses from intake pigeonholes and waiting perches, through a rounded mediation table and privacy screen, to a tribunal bench, precedent vault, compliance seal, and settlement tray. The muted mulberry, charcoal, oatmeal, brass, and smoked-glass palette distinguishes labor administration from both warm Rooster supervision and cool IT automation while remaining part of the same architectural kit.

## Flock Provisions Co-op: feed as working capital

Flock Provisions turns the Feed Fund's oldest obligation into a real supply chain. Without stored grain, daily demand is bought automatically on the spot market; commissioning the Co-op adds finite storage, prepaid FIFO lots, ration quality, spoilage, and one review-time procurement authorization per day. The flock can never soft-lock because every uncovered scoop remains an automatic closing obligation.

Daily demand is an integer quantity:

```text
feed demand = 3 scoops + one scoop per active hen
```

Existing directive and incident adjustments use the same `$2 = one scoop` conversion. Before the seasonal calendar opens, this preserves the original bill exactly: four hens require seven scoops and cost $14; six hens require nine and cost $18. From the market calendar onward, the deterministic Farm Mutual season also sets the grain quote: Spring 90% of the $2 base, Summer 110%, Autumn 100%, and Winter 135%. Reloading cannot reroll a price.

| Provisions tier | Day / desks / active hens | Capital | Total upkeep | Storage | Supplier file unlocked |
|---|---:|---:|---:|---:|---|
| Level 1: Receiving Hopper | 4 / 4 / 4 | $80.00 | $4.00 | 18 scoops | Local Whole Grain |
| Level 2: Dry Grain Reserve | 8 / 5 / 5 | $140.00 | $8.00 | 36 scoops | Inspirational Bulk Mash |
| Level 3: Feed Futures Desk | 12 / 6 / 6 | $220.00 | $13.00 | 54 scoops | Fixed Future Reserve |

| Order | Quantity and quote | Shelf life | Consumed-ration effect |
|---|---|---:|---|
| Local Whole Grain | One next-shift demand at 125% of spot | 2 shifts | Work strain 92%; flock morale +2 |
| Inspirational Bulk Mash | Three demands at 85% of spot | 3 shifts | Work strain 105%; named-hen grievance +1 |
| Fixed Future Reserve | Four demands at the current spot quote | 4 shifts | Neutral ration; protects against a later seasonal increase |

Orders debit exact integer cents once when authorized. Stored lots are then consumed oldest-first. Their prepaid acquisition value remains visible in the inventory receipt but is not charged again at closing. The shift's Feed cost contains only automatic spot shortage; the farmer review separately itemizes stored scoops, spot scoops, prepaid working capital, closing stock, and recognized spoilage. Repeated same-day demand reconciliation restores and reruns the same FIFO plan instead of consuming or booking spot spend twice.

Flockwatch hosts the loop inside its existing scroll rather than opening another modal. It shows the live seasonal quote, stock versus capacity, next demand, projected post-ration stock, coverage, shortage obligation, and three stable offer cards. Every card discloses quantity, unit and total prepaid cost, shelf life and expiry, ration consequences, availability, and the exact authoritative hold reason. The last delivery, consumption, and spoilage receipts remain visible, and the automatic-spot fallback is stated explicitly so declining to order is always a valid choice.

The southwest governance parcel at `Rect2((4.10, 27.10), (6.40, 5.80))` now completes the campus block opposite Rooster Operations. A `1.20m` east door connects through the exact bridge at `Rect2((10.50, 29.40), (0.25, 1.20))`; the `1.10m` internal aisle remains clear. The cumulative room grows from a buying desk, floor scale, and receiving hopper to twin galvanized hoppers and an overhead auger, then a signature strategic-reserve silo, caged ladder, climate cabinet, and futures board. Physical sack count, hopper fill, reserve gauge, quote, expiry lamp, and spoilage state come only from the canonical procurement snapshot. The module adds no collision or navigation geometry.

Schema v18 appends an eleventh stable facility key and a strict nested feed ledger. Schema-v17 migration adds an unowned Co-op with no lots, orders, consumption, spend, or spoilage. Current saves validate lot identity, FIFO quantities, authored ration effects, acquisition value, expiry, capacity, daily versus lifetime ledgers, and last receipts before mutating the live simulation.

## Harvest Credit Gallery: publicity from somebody else's basket

The Farmer Relations lease is implemented as the **Harvest Credit Gallery**, a three-tier public-attribution room rather than a passive reputation multiplier. Every campaign begins with one frozen completed-shift record: day, clutch target, total eggs, sound eggs, cracked eggs, golden eggs, quota result, the top layer's identity, and the same factual hen highlight used by the closing report. The Gallery cannot invent a better shift after reload, and the interface never recomputes its terms.

| Gallery tier | Day / desks / active hens | Packing dependency | Capital | Total upkeep | Visible construction |
|---|---:|---:|---:|---:|---|
| Level 1: Basket Profile Plinth | 5 / 4 / 4 | Packing Annex 1 | $90.00 | $5.00 | Lit basket, portrait easel, and named-layer plate |
| Level 2: Clutch Press Backdrop | 9 / 5 / 5 | Packing Annex 2 | $150.00 | Results board, fabric press wall, camera, and warm key lights |
| Level 3: Attribution Archive | 13 / 6 / 6 | Packing Annex 3 | $240.00 | Permanent byline wall, awards, farmer portrait, and campaign archive |

After the mandatory closing credit memo clears, Flockwatch pauses at one optional publication gate. Management may file exactly one of three campaigns or explicitly skip it:

| Campaign | Publicity basis | Relationship meaning | Satirical cost |
|---|---|---|---|
| Layer Profile | The top-ranked named hen and her real shift | Strong recognition for one producer | Farmer favor falls; the ranking still excludes invisible labor |
| Clutch Results Board | The whole flock's actual sound, cracked, golden, and quota result | Shared trust, morale, and solidarity | Farmer favor falls farther because the evidence names the flock |
| Farmer's Method | The same clutch reframed as management technique | Fastest cash and public-standing growth | Trust and compliance fall, grievance and stress rise, and tomorrow's quota increases |

Every offer publishes its exact integer payout and effects before authorization. Standing gain is:

```text
choice reach + (gallery level - 1) + quota success + min(2, golden eggs)
```

The base publicity payout uses actual sound and golden eggs. Its per-sound-egg schedules are 20/25/30 cents for Layer Profile, 15/20/25 cents for Clutch Results, and 35/45/55 cents for Farmer's Method. Golden bonuses are $1/$1.50/$2, $0.75/$1/$1.25, and $2/$3/$4 respectively. Prior standing adds 0.5% per point, capped at 25%, and the complete integer payout is credited once. The standing ladder is Unlisted, Roadside Notice, County Fair, Regional Showcase, then Household Farm Brand.

The west care-campus bay is an exact `6.4m × 5.8m` parcel at `Rect2((4.10, 21.10), (6.40, 5.80))`, opposite the Training Roost. Its east bridge is `Rect2((10.50, 23.40), (0.25, 1.20))`; the `1.10m` clear aisle reaches the existing spine without crossing a chicken route. Warm barn red, oat linen, walnut, and aged brass keep the room farm-native while every changing number remains attached to a results board, nameplate, receipt, or archive surface.

The room identity and evidence hierarchy are physical, not world-space UI. A modeled walnut-and-brass **HARVEST CREDIT GALLERY** fascia carries the overview landmark; closer data stays attached to a plinth screen, press-results board, credited-layer portrait and receipt, or attribution wall. Framed low-alpha glazing, perimeter roof structure, connected basket/light hardware, and distinct hen/farmer portrait silhouettes keep those exhibits from reading as floating cards or disconnected placeholder parts.

Schema v19 appends the twelfth stable facility key plus a strict publicity ledger. Schema-v18 migration adds an unowned Gallery with zero standing, no attribution drift, no frozen evidence, and no campaign or skip receipt. Current saves validate the exact facility dependency, chronological one-per-day history, cumulative payout, bounded standing and attribution, frozen shift evidence, and filed/skipped review status before mutating live state.

## Implemented expansion: Farmgate Dispatch Depot

The Depot completes the production chain after grading and presentation. Once level one is commissioned, every sound or golden egg is stored as an immutable FIFO lot carrying its claim, laying day, named worker, quality, recorded value, installed tier, shelf life, and expiry day. That recorded value is not credited to the Feed Fund at laying time. Cracked eggs retain their existing immediate accounting, and a failed ledger write safely falls back to immediate Farmer Pickup rather than destroying earned value.

| Tier | Day / desks / active hens | Required dependencies | Capital | Total upkeep | Storage / shelf life | County route | Visible construction |
|---|---|---|---:|---:|---|---:|---|
| Level 1: Roadside Loading Shed | 6 / 4 / 4 | Packing 1, Gallery 1, standing 5 | $120.00 | $7.00 | 12 eggs / 2 shifts | 8 eggs | Low timber-and-canvas shed, manual scale, twelve-cell cold basket, and split-flap route slate |
| Level 2: Chilled County Dock | 10 / 5 / 5 | Packing 2, Gallery 2, standing 12 | $200.00 | $13.00 | 24 eggs / 3 shifts | 16 eggs | Galvanized sawtooth cold shed, condenser, raised dock, conveyor, and second storage bank |
| Level 3: Regional Route Fleet | 14 / 6 / 6 | Packing 3, Gallery 3, standing 25 | $320.00 | $22.00 | 42 eggs / 4 shifts | 24 eggs | Barn-red dispatch tower, loading mast, 42-cell cumulative rack, and Farmer Brand refrigerated truck |

Storage pressure is real but non-destructive. A new egg that exceeds installed capacity is sold immediately for 90% of its recorded value and appears in the overflow ledger. At close, every retained egg costs $0.20 and every expired egg costs $0.25 to dispose of. Settlement debits those costs against route proceeds, keeps the Feed Fund non-negative, and freezes one exact receipt with the sold and expired lots, base value, gross, commission, listing fee, payout, carrying cost, disposal, overflow, retained stock, and net cash delta.

One review-time dispatch mandate determines how eligible lots settle:

| Mandate | Selection and price | Fee / gate | Strategic meaning |
|---|---|---|---|
| Farmer Pickup | Every eligible lot at 100% recorded value | No fee; safe default when no mandate is filed | Clears risk and working inventory without upside |
| County Auction | Oldest eggs first, limited to 8 / 16 / 24 by tier, at the frozen deterministic seasonal quote | 5% of gross | Exposes stock to market timing while preserving newer lots |
| Regional Showcase | Up to six golden-first, then highest-value eggs, at 160% plus 0.5% per public-standing point up to +25% | $3 listing fee; level 3 only | Concentrates premium output into a small reputation-priced route |
| Hold the Basket | No sale | Feed Fund must already cover protected close obligations | Deliberately carries inventory into a later market at cold-chain and expiry risk |

Authorizing a mandate freezes day, installed tier, route limit, season, quote, public standing, standing bonus, and listing fee. Reloading cannot reroll those terms. Farmer Pickup is synthesized as the exact default if the player files nothing, so the economy never deadlocks behind an omitted review action.

The physical Depot occupies `Rect2((18.65, -8.90), (8.80, 11.80))` east of Packing, with an exact `0.25m × 1.20m` entrance bridge, protected `1.10m` pedestrian aisle, and separate `3.35m × 10.90m` truck lane. Locked, surveyed, and all three cumulative operating states share one stable camera focus. Stock cases, age tags, route slate, overflow/spoilage lamps, truck manifest, and route vehicle mirror only authoritative state; the visual creates no collision or navigation geometry and preserves every existing chicken route.

Schema v20 appends the thirteenth stable facility key plus strict Farmgate inventory, mandate, settlement, pinned-plan, last-commissioning, and bounded commissioning-history ledgers. Neutral schema-v19 migration adds an unowned Depot and empty ledgers without reclassifying any previously credited egg or changing the saved Feed Fund. Current restore rejects malformed dependencies, lots, chronology, frozen terms, math, unknown plan IDs, and altered commissioning effects before mutating live state.

## Capital Blueprint and commissioning reveal

The Capital Blueprint is the primary expansion surface for all thirteen facilities. It maps the stable Production, Flock, and Governance parcels at full screen, filters them by ready, blocked, or owned state, and gives the selected parcel one exact **Why now / You get / You owe / After build / Gates** inspector. The former inline facility list remains available only as an explicit fallback, keeping staffing and operating work visible without making the player scroll past every capital file.

Pinning a parcel records a persistent `pinned_capital_plan_id` and its live facility status; it is a planning action, not a purchase or reservation of funds. The plan survives save/restore, updates as gates change, can be cleared explicitly, and clears automatically only when its facility becomes fully commissioned. Unknown and already-maxed IDs reject without changing the prior plan.

Every accepted facility tier produces one strict commissioning receipt from the authoritative transaction. It contains facility and level identity, purchase day, tier and maximum tier, exact cost, Feed Fund before/after, spendable cash before/after, protected reserve before/after, upkeep before/after and delta, plus copied installed benefits, tradeoffs, storage, dispatch, and shelf-life effects. Rejected purchases append nothing. Accepted receipts are retained in a bounded 32-entry history and drive a player-held reveal over the real focused construction: the reveal remains until **Continue** or **Return to Blueprint**, so a physical purchase cannot disappear behind a short camera animation.

## Implemented expandable campus: North Meadow

North Meadow is the first player-owned parcel outside the fixed thirteen-facility ledger. It appears in the Capital Blueprint from day one and becomes purchasable after either Farmgate Dispatch Depot level one or two Bronze Farm Mutual standing points. The planner keeps land, services, module placement, recurring cost, and blocked-route reasons together rather than presenting them as unrelated upgrades.

| Campus action | Capital | Added daily cost | Visible and economic result |
|---|---:|---:|---|
| Buy North Meadow deed | $85.00 | $3.00 | Opens the `12.80m x 11.80m` meadow and its surveyed build pads |
| Connect circulation | $28.00 | $1.50 | Commissions the protected `2.10m` service-and-walking spine |
| Connect power | $35.00 | $2.25 | Energizes the parcel and satisfies the routing pod's second operating dependency |
| Connect cold chain | $60.00 | $4.00 | Enables six additional Farmgate storage lots once the pod is operational |
| Place Egg Routing Pod | $75.00 | $5.00 | Adds six live claim slots only when circulation and power are commissioned |
| Relocate the pod | $18.00 | $0.00 | Moves the installed module between the two legal pads without duplicating it |

A fully commissioned meadow costs $283.00 in capital and $15.75 per day. The optional relocation raises lifetime capital spend to $301.00 without changing upkeep. `Meadow West` and `Meadow East` are valid module sockets; `Service Spine` is deliberately rejected because it would block circulation. Rejections are atomic, preserve the Feed Fund, and explain the physical reason in the same planner that issued the request.

The world moves through readable deed, site-work, connected-services, placed-pod, operational, and cold-chain stages. Survey stakes, trench and meter hardware, socket pads, the blocked service spine, and the movable Egg Routing Pod all mirror authoritative state. Buying the deed expands the overview camera from the installed campus bounds and publishes the exact reserved navigation footprint; an unowned meadow changes neither. The parcel touches Farmgate's north edge with a `0.20m` seam while preserving the office's existing circulation clearances.

Schema v21 appends a strict `campus_expansion` save ledger beside the thirteen-key facility ledger. Neutral schema-v20 migration creates an unowned meadow with no services, module, cost, benefit, or history. Current restore validates parcel ownership, service dependencies, legal socket identity, recurring totals, receipts, Farmgate capacity, and construction stage before mutating live state.

## Implemented multi-parcel Campus Portfolio

Schema v22 extends the campus without changing the thirteen fixed facility keys or replacing North Meadow. Its independently validated `campus_portfolio` ledger owns two later deeds, four legal pads, four module identities, FIFO construction projects, frozen historical prices, named staffing, and a bounded receipt chain. Neutral schema-v21 migration creates no Orchard/Creekside ownership, construction, staffing, spending, or benefit; current Department schema v24 retains that contract alongside the Treasury journal.

| Deed or module | Unlock / location | Capital | Added daily cost | Build | Staffed operating result |
|---|---|---:|---:|---:|---|
| Orchard Row deed | Day 6; Orchard West/East | $125.00 | $4.50 | Immediate deed filing | Opens two real construction pads |
| Creekside Yard deed | Day 9 after Orchard Row; Creekside West/East | $165.00 | $5.50 | Immediate deed filing | Opens two cold-campus pads |
| Collection Rail Hub | Orchard Row | $140.00 | $6.00 | 2 shifts / 1 contractor | +4 live files and +$0.25 per sound/golden egg |
| Grain Recovery Mill | Orchard Row | $160.00 | $7.00 | 3 shifts / 1 contractor | +18 prepaid-grain storage and one fewer daily feed scoop |
| Creekside Chilling Exchange | Creekside Yard | $200.00 | $9.00 | 3 shifts / 2 contractors | +12 finished-egg slots and 95% rather than 90% overflow pickup |
| Contractor Roost | Creekside Yard | $130.00 | $5.00 | 2 shifts / 1 contractor | +1 shared contractor slot and access to the two-slot Exchange build |

The portfolio starts with one contractor slot. Authorizations that fit capacity become active; later valid work queues in immutable FIFO order and mobilizes as slots free. Projects reserve their declared power/cold requirements, advance once per completed shift, and become installed only at completion. Contractor Roost adds its second slot only after it is itself complete, powered, and staffed; the Chilling Exchange still requires two simultaneous slots. The planner compares exact Feed Fund, protected reserve, daily cost, queue position, contractor/power/cold capacity, pad compatibility, and disabled reason before it emits player intent.

Installed does not mean operational. Each module needs one available named employed hen plus its declared shared utility capacity. Assigning the first hen adds a $1 daily campus-duty premium. She immediately stops desk production, physically walks the authored desk/aisle/campus route, and holds at the module-facing duty socket; unassignment or reassignment sends her through the full return path before claim/egg eligibility resumes. A module without its worker or utilities retains its paid geometry and upkeep but provides no economic bonus.

Every accepted campus action reconciles the live world before presenting its receipt. Deed stakes become owned land; an active project exposes its foundation, queued work exposes survey staging, a boundary completion exposes the permanent module, contractor mobilization exposes the next active stage, and staffing begins the named commute. The opaque portfolio closes, the camera focuses the exact parcel or module/pad, and a player-held **Campus Build Reveal** preserves identity, location, cost, daily obligation, capacity, worker, effects, and outcome until acknowledgement. **Continue** advances through queued boundary receipts; **Return to Portfolio** (or `Esc`) restores the planner. Neither route rewinds the accepted transaction, and reduced-motion mode removes only the short entrance animation.

## Senior Roost annual Board Mandates

The nested Senior Roost state is schema v5 and remains independent of both Department schema v24 and the outer campaign envelope. At the start of each Senior year it freezes exactly three deterministic mandate offers from the opening day, quota, Feed Fund, unlocked tier, and permanent Book-success ledger. The first offer is always the free **Standard Board Book**, so a player can never be deadlocked by an unaffordable stake. The scheduler also preserves the hardest unlocked tier and prefers an eligible first-clear Book for the remaining variety slot whenever one exists. Existing schema-v1 through schema-v4 careers retain their exact already-frozen cards under the legacy rotation. The existing `1`-`3` card selection and `Enter` authorization flow files the mandate before the first-quarter capital policy.

| Seal tier | Permanent seals required | Available books | Stake | Success |
|---|---:|---|---:|---|
| Tier 0 | 0 | Standard Board Book, Shell Stewardship Book, Flock Continuity Accord | 0 marks | 1 Board Seal |
| Tier 1 | 1 | Mutual Assurance Guarantee or Executive Harvest Commitment | 2 marks | Stake returned; 2 Board Seals |
| Tier 2 | 3 | Rested Flock Covenant | 4 marks | Stake returned; 3 Board Seals |
| Tier 3 | 6 | Gold Standard Book | 6 marks | Stake returned; 4 Board Seals |

An advanced stake is reserved immediately and excluded from available Roost Marks, so it cannot also fund a Career Sponsorship. Each accepted Senior shift adds exactly one compact evidence row covering quota result, eggs/shell loss, credited harvest, welfare, compliance, farmer favor, wage arrears, and closing Feed Fund. Flockwatch's Senior Career + Board Forecast shows twelve-shift progress, objective actuals/targets, the next threshold, and the largest recoverable blocker; every three-shift quarter freezes that checkpoint in its review.

At twelve shifts the annual mandate settles once. Success returns the exact advanced stake and files the listed permanent seals; failure permanently spends the stake and awards no seals. The free tier forfeits nothing on failure. The ordinary Senior annual pass/fail, quota change, bonus marks, promotion, and next-year continuation remain separate, so a good Board filing cannot overwrite a poor career review or vice versa. Continuing opens a fresh three-offer mandate gate. Schema-v2 Senior files migrate without invented success: untouched first years receive fresh offers, while a year already in progress receives a grandfathered no-stake book whose eventual settlement awards and forfeits nothing.

The deterministic native art hooks write their results under `captures/`:

```powershell
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-farmgate-locked
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-farmgate-survey
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-farmgate-l1
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-farmgate-l2
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-farmgate-l3
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-dispatch-campus
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-capital-blueprint
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . -- --capture-commissioning-reveal
& "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --path . --resolution 2560x1440 -- --capture-campus-expansion
```

## Existing physical expansion tiers

The current four-hen office already supports two workstation authorizations:

| Expansion | Capital | Daily overhead | Visible result |
|---|---:|---:|---|
| Claims Bay A | $25.00 | $2.00 | Boxed perch becomes workstation five |
| Claims Bay B | $55.00 | $2.00 | Boxed perch becomes workstation six |

Hiring remains separate. Capacity buys a physical workplace and overhead; hiring fills it with a named hen, wage, specialty, relationships, and career history.

The Farm Mutual Contract Board and Service Coop form one closed demand-and-investment loop: larger records tiers and staffing unlock riskier client books, successful books earn standing, and standing unlocks visible capacity-dependent construction that improves future settlements. Wellness and Training form a second loop around real strain, contract welfare exposure, career development, quota pressure, and payroll. Rooster Operations, IT, and Flock Relations form a third around management span, automation, recurring labor cost, surveillance, compliance, workplace cases, and resolution liability. Flock Provisions adds a fourth around seasonal operating inputs, storage capacity, ration quality, working capital, and waste. Harvest Credit and Farmgate Dispatch form a fifth around real completed output, public standing, attribution, finite finished-goods inventory, market timing, route fees, and spoilage. Future facilities should extend those patterns with disclosed requirements, visible work entering the office, and benefits that settle only from authoritative production.

## Expansion architecture

The facility catalog is deliberately data-driven: stable ID, display copy, per-level capital, total maintenance schedule, maximum level, day/milestone gates, benefits, tradeoffs, and effect values live together. Snapshots expose current tier, next tier, maintenance delta, exact reserve projection, and causal effects to the UI; the visual layer reads ownership, carton progress, Farmgate stock, and frozen receipts but never invents economic state.

The schema-v23 economy combines the thirteen-key facility ledger, North Meadow's independent `campus_expansion`, the later `campus_portfolio`, and the conserving Farm Treasury journal. The internal Candling & Rework Bay and twelve external facilities retain stable authored footprints. North Meadow proves explicit land/services/socket commissioning; Orchard Row and Creekside prove multi-shift queued construction, finite shared resources, authored path expansion, and named staffing. All benefits remain conditional on real physical dependencies, while every capital and operating cent closes through one protected journal.

The implemented expansion contract is now:

- buy one of three authored deeds without rewriting earlier parcel history;
- commission explicit circulation, power, and cold-chain services or reserve finite shared units;
- place only a compatible data-driven module on a legal, route-safe pad;
- expose queued/foundation/frame/completed construction in the live world for its real duration;
- require a named employed hen to commute into and visibly staff productive campus equipment;
- apply capital, upkeep, duty premium, capacity, and settlement effects only from authoritative state;
- hold the exact deed/project/boundary/staffing receipt over the focused world until the player acknowledges it;
- migrate v21 to v22 with a neutral portfolio, then v22 to v23 with a neutral Treasury, preserving every earlier parcel, desk, worker, receipt, route, and cent.

Future rooms should follow the annex contract: locked parcel, readable survey state, cumulative construction, an economic loop visible in the room, a real recurring obligation, strict route clearance, responsive requisition UI, and neutral save migration. Empty square footage does not count as expansion.
