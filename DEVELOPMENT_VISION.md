# Pecking Order

## Godot and Blender Development Vision

### Purpose

This document translates the creative concept in [GAME_CONCEPT.md](GAME_CONCEPT.md) into a practical direction for a 3D management, economy, and incremental game built with Godot and Blender.

The recommended form is a stylized office-management simulation presented as a detailed tabletop diorama. The visible office should be lively, readable, and funny; underneath it, a centralized simulation should track labor, production, morale, money, mistakes, and power.

The central design opportunity is to make optimization itself part of the satire. The player should enjoy improving the office while gradually recognizing what—and whom—they are optimizing.

---

## Product Direction

### Genre

*Pecking Order* combines:

- Management simulation
- Workplace tycoon
- Resource economy
- Incremental progression
- Light office construction
- Character-driven systemic storytelling
- Dark corporate satire

It should not become a fully realistic business simulator, a complex architectural builder, or an idle game that mostly plays itself. Its identity comes from visible workers, understandable production chains, difficult management choices, and the absurd transformation of office work into egg production.

### Recommended Player Role

The player is a newly promoted rooster assigned to manage an underperforming insurance department.

This role creates the strongest relationship between mechanics and theme. The player can:

- Hire and assign hens.
- Arrange workstations and facilities.
- Set priorities and enforce policies.
- Approve breaks, training, and benefits.
- Inspect performance dashboards.
- Report results to the farmer.
- Claim credit, share credit, or conceal failures.
- Protect workers or sacrifice them to meet targets.

The player begins close enough to the hens to understand their working conditions but receives rewards for distancing themselves from those conditions. Promotion therefore changes more than numbers: it changes what the player can see, control, and justify.

An alternative campaign could later allow the player to begin as a hen, but the management-focused first version should commit to the rooster perspective.

### Creative Touchstones

The intended experience can be described as:

- The readable institutional comedy of *Two Point Hospital*.
- The visible production flow and optimization satisfaction of *Factorio*.
- The accumulating moral discomfort of *Papers, Please*.
- The character attachment and emergent incidents of *RimWorld*.

These are directional references, not feature checklists. The initial game should remain considerably smaller in scope.

---

## The Corporate Insurance Office

### Setting

The office should resemble a regional insurance-processing center from roughly 1985–2005. It is neither futuristic nor luxurious. It is an environment designed around inexpensive repetition:

- Beige cubicle partitions
- Gray patterned carpet
- Fluorescent ceiling panels
- CRT or early flat-panel computers
- Filing cabinets and paper trays
- Artificial plants
- Motivational posters
- Break-room vending machines
- Cheap rolling chairs adapted for chickens
- Frosted-glass meeting rooms
- An executive office that is visibly nicer than everything around it

The mundane insurance setting helps the satire because the work is abstract, procedural, and easily measured. Claims arrive, chickens process them, decisions are stamped, and the consequences are usually experienced by someone outside the building.

### Spatial Presentation

Use a three-quarter orthographic camera with rotation and stepped zoom levels. The office should feel like a physical model the player can inspect.

The camera should support:

- Pan
- Rotate in fixed increments
- Zoom between department and worker detail
- Focus on a selected chicken or incident
- Jump to alerts without disorienting the player
- Hide or fade obstructing walls

The first office should be a single floor rather than a multi-story building. Expansion can unlock adjacent rooms or departments without requiring complicated vertical construction.

### Readability Rules

- Important actions must have distinct silhouettes.
- Workstations need visible states: waiting, active, blocked, broken, or overloaded.
- Eggs must remain visible as they travel through production.
- Employee condition should be readable through posture and animation before opening a panel.
- Decorative clutter must not obscure interactive objects.
- UI overlays should explain the simulation without replacing the physical office.

---

## Core Experience

### The Workday Loop

1. **Morning briefing:** The farmer or regional rooster announces priorities, quotas, and a new initiative.
2. **Intake:** Insurance claims, policy changes, or customer requests enter the department.
3. **Assignment:** The player routes work and assigns chickens to stations or specialties.
4. **Processing:** Hens peck through cases while using energy and accumulating stress.
5. **Laying:** Completed work becomes eggs at nesting stations.
6. **Inspection:** Eggs are assessed for quantity, accuracy, quality, and risk.
7. **Collection:** Approved eggs are stamped, credited, and sent to the farmer.
8. **Consequences:** Poor decisions return as complaints, audits, rework, or reputational damage.
9. **Review:** The player receives money, authority, blame, and new targets.
10. **Investment:** The player hires staff, rearranges the office, buys equipment, or changes policy.

### Why Eggs Matter

Eggs are physical representations of otherwise invisible knowledge work. They allow players to watch value move through the hierarchy.

Eggs should have several attributes:

- **Volume:** How much work was completed.
- **Shell quality:** The general standard of the work.
- **Accuracy:** Whether the claim or policy was processed correctly.
- **Customer value:** Whether the result helped the insured party.
- **Compliance:** Whether required procedures were followed.
- **Risk:** The chance of future rework, complaint, or audit.
- **Innovation:** Rare improvements that may become golden eggs.

An egg can appear impressive while containing hidden risk. The farmer primarily values what can be shown during the next presentation, creating pressure to trade long-term stability for visible short-term output.

### The Delayed-Consequence Loop

Decisions should return later rather than resolving immediately.

Examples:

- Rushing a claim produces an egg quickly but may create rework two days later.
- Denying difficult claims improves current throughput but damages reputation.
- Skipping breaks raises output until absence and burnout increase.
- Underfunding compliance saves feed until an audit occurs.
- Promoting the best layer removes a productive worker from production.
- Raising quotas increases the next reporting period’s baseline expectations.

This loop prevents the game from becoming a simple race to make numbers larger. Every apparent efficiency may create organizational debt.

---

## Management and Economy

### Primary Resources

The economy should use a small group of interconnected resources:

| Resource | Meaning | Primary Uses | Primary Risks |
| --- | --- | --- | --- |
| Eggs | Completed deliverables | Meet quotas and contracts | Low-quality output creates rework |
| Revenue | Department budget | Hiring, furniture, facilities, upgrades | Excessive growth raises expectations |
| Feed | Compensation and operating supply | Sustain workers and improve retention | Cuts cause stress and resentment |
| Morale | Immediate emotional condition | Supports quality and resilience | Can be temporarily manipulated |
| Reputation | Public and customer trust | Attract contracts and reduce scrutiny | Denials and scandals reduce it |
| Compliance | Procedural safety | Prevent audits and catastrophic failures | Slows visible throughput |
| Executive confidence | Farmer’s faith in the player | Unlocks budget and authority | Encourages presentation over reality |
| Solidarity | Collective worker power | Cooperation, resistance, and bargaining | Threatens management control |

Revenue and feed should use integer units. Percentages and needs may use normalized values, but exact financial values should not rely on floating-point arithmetic.

### Resource Relationships

Resources should interact rather than operate as separate progress bars.

For example:

> Surveillance increases short-term peck rate, reduces morale, increases hidden errors, and gradually raises solidarity.

> Higher feed allowances reduce immediate profit but improve retention, quality, and trust.

> Strong compliance reduces output speed but protects the department from delayed disasters.

> High executive confidence unlocks funding while raising future quotas and pressure.

The player should always be able to inspect a clear breakdown of income, costs, productivity modifiers, and major risks. Satire can be opaque; strategy should not be.

### Growth and Organizational Debt

Growth should introduce new costs and coordination problems:

- More hens require more desks, nesting capacity, feed, and supervision.
- More roosters add meetings, reviews, and reporting overhead.
- More equipment requires maintenance and IT support.
- More departments create communication delays and duplicated work.
- Higher production establishes more demanding future targets.
- Automation reduces some labor while creating maintenance and compliance risks.
- A larger workforce increases the consequences of poor policy.

Upgrade costs may grow exponentially, but the meaningful constraint should be organizational complexity rather than price alone.

### Resource Caps and Logistics

Avoid unlimited storage. Physical capacity should matter:

- Incoming trays limit queued claims.
- Nesting stations limit simultaneous egg completion.
- Egg storage limits unreported work.
- Feed storage limits operational reserves.
- Filing capacity affects compliance and retrieval speed.

These constraints give office layout a direct relationship to the economy.

---

## Chicken Simulation

### Worker Attributes

Each hen should be defined by a compact set of attributes:

- Pecking speed
- Accuracy
- Domain knowledge
- Stress tolerance
- Sociability
- Ambition
- Trust in management
- Solidarity

Attributes should create understandable strengths and conflicts rather than minor numerical variations.

### Needs

Limit the initial simulation to four needs:

- Hunger
- Fatigue
- Stress
- Social connection

Additional meters will make the game harder to read without necessarily producing better decisions. Health, burnout, and absence can emerge from the interaction of these needs.

### Worker States

Visible behavior can be driven by states such as:

- Arriving
- Seeking work
- Working
- Requesting help
- Attending a meeting
- Resting
- Eating or drinking
- Socializing
- Laying an egg
- Carrying or inspecting an egg
- Hiding an error
- Organizing
- Panicking
- Burning out
- Leaving the office

The economic simulation determines intent; the 3D character performs an animation representing that intent.

### Relationships and Autonomy

Chickens should not behave as programmable machines. Relationships and traits can occasionally alter their behavior:

- A trusted hen covers another’s mistake.
- An ambitious hen reports a struggling coworker.
- A sociable hen spreads morale through the break room.
- A veteran refuses an obviously harmful shortcut.
- A frightened worker hides a cracked egg.
- A highly organized team coordinates an unofficial slowdown.

These actions should be uncommon and clearly communicated so they feel like character moments rather than random sabotage.

### Management Span

The player should directly understand approximately 6–12 workers during the first campaign. Larger departments can introduce supervisors and aggregate reporting, but the game should resist turning every chicken into an anonymous statistic.

The loss of personal visibility at higher ranks can itself become a mechanic. The more the player delegates, the more they depend on dashboards that simplify or distort reality.

---

## Incremental Progression

### Progression Layers

Progression should unfold across four layers:

1. **Worker:** Better skills, equipment, and relationships.
2. **Team:** Improved workflow, facilities, and policies.
3. **Department:** New specialties, supervisors, and production chains.
4. **Corporation:** Executive politics, automation, public reputation, and labor organization.

### Useful Unlocks

Good unlocks create new decisions rather than flat bonuses:

- Training programs that trade current output for future skill.
- Specialist claim types with higher value and risk.
- Assistant roosters who reduce micromanagement but filter information.
- Automation that handles routine work but creates maintenance dependencies.
- Flexible schedules that improve retention while complicating staffing.
- Performance dashboards that reveal some metrics while encouraging fixation on them.
- Union representation that changes policy decisions into negotiations.
- Public-relations programs that can address or merely conceal reputation problems.

### Automation

Automation should reduce repetitive player actions without removing meaningful choices.

The player may automate:

- Routine work assignment
- Break scheduling
- Egg transport
- Basic purchasing
- Low-risk claim processing

The player should not fully automate:

- Ethical policy decisions
- Promotions and layoffs
- Crisis responses
- Negotiations
- Credit attribution
- Major investments

---

## Godot Technical Direction

### Architectural Principle

The 3D office is a presentation of the simulation, not the simulation itself.

```text
Definitions and balancing data
        ↓
Authoritative simulation state
        ↓
Central simulation tick
        ↓
Economy, work, needs, relationships, and events
        ↓
State-change signals
        ↓
3D agents, animations, audio, effects, and interface
```

This separation allows the game to fast-forward, save cleanly, simulate off-screen departments, and remain testable without rendering the office.

### Simulation Tick

Use a central tick manager rather than giving every worker independent simulation logic in `_process()`.

Recommended initial settings:

- Pause
- Normal speed
- 3× speed
- 10× speed
- Four to ten simulation ticks per real-time second at normal speed
- Visual interpolation between simulation updates

Rendering remains frame-based, while work, needs, and economic outcomes advance through deterministic simulation ticks.

### State Ownership

Suggested responsibilities:

- `SimulationManager`: owns time and coordinates each tick.
- `EconomyState`: owns revenue, expenses, feed, and transactions.
- `DepartmentState`: owns work queues, facilities, policies, and quotas.
- `ChickenState`: owns an individual chicken’s attributes, needs, relationships, job, and current intent.
- `EventDirector`: evaluates conditions and schedules incidents.
- `SaveManager`: serializes authoritative state and progression.
- `OfficeView`: creates and updates visible 3D representations.
- `HUD`: listens for state changes and presents information.

UI controls should request actions through the appropriate controller. They should never directly change currency, worker needs, or production totals.

### Data-Driven Content

Use custom Godot `Resource` definitions for content that designers will balance:

- Chicken archetypes
- Jobs and specialties
- Work item types
- Egg quality rules
- Furniture and facility definitions
- Policies
- Upgrades
- Events
- Contracts and quotas
- Dialogue and presentation lines

Runtime instances must duplicate mutable resources or store mutable state separately so one worker cannot accidentally modify the shared definition used by every worker.

### Suggested Project Organization

```text
res://
  core/
    simulation/
    save/
    events/
  features/
    chickens/
    work/
    eggs/
    economy/
    office_building/
    policies/
    presentations/
  content/
    chickens/
    furniture/
    work_types/
    policies/
    events/
  environments/
    office/
  ui/
  audio/
  tests/
```

Organize scenes, scripts, and resources by feature. A chicken feature should contain its relevant scene, scripts, data definitions, and tests rather than scattering them across folders based only on file type.

### Navigation

Use Godot’s 3D navigation for visible chicken movement, but do not make path traversal authoritative for production. If a chicken becomes visually stuck, the economic simulation should not permanently collapse.

Recommended approach:

- Workstations, nests, doors, and facilities expose interaction points.
- The simulation assigns a destination and intent.
- The view agent navigates to the appropriate interaction point.
- Arrival triggers or synchronizes the visible animation.
- Timeouts recover agents that cannot reach a destination.

Navigation should be updated only when destinations or office geometry change, not every frame for every worker.

### Save Data

Save authoritative values rather than entire nodes or scenes:

- Current date and shift time
- Economy balances and transaction history
- Department layout identifiers and transforms
- Worker IDs, attributes, needs, relationships, and assignments
- Active policies and upgrades
- Work queues and unresolved consequences
- Progression flags and event history

Use versioned save data with defaults for newly added fields. This allows later builds to load earlier saves safely.

### UI

The interface should support both immediate reading and detailed inspection:

- Top-level resource bar
- Time and speed controls
- Alerts and incident queue
- Selected worker or facility panel
- Income and expense breakdown
- Productivity and quality trends
- Policy panel
- Farmer expectations and reporting-period goals

Update interface elements when data changes rather than refreshing every label each frame. Use responsive Godot `Control` containers so the interface remains usable across common desktop resolutions.

---

## Blender Asset Pipeline

### Modular Office Kit

The office should be built from reusable modules rather than unique rooms.

Initial environment kit:

- Floor tiles
- Straight and corner wall pieces
- Doorway and window pieces
- Cubicle wall segments
- Desk variations
- Chicken-compatible chairs
- Filing cabinets
- Storage shelves
- Meeting table pieces
- Nesting stations
- Feed and water stations
- Fluorescent ceiling fixtures
- Artificial plants
- Waste bins and office clutter
- Computers, phones, printers, and paper trays

Choose a consistent building grid, such as one- or two-meter increments. Keep pivots and origins standardized so pieces snap predictably in Godot.

### Chicken Production

Use one primary skeleton for hens and a compatible variation for roosters. Character variety should come from modular parts and materials rather than unique rigs.

Variation sources:

- Feather palettes and patterns
- Comb and wattle shapes
- Beak and body proportions
- Ties, glasses, badges, headsets, and lanyards
- Supervisor jackets or vests
- Stress, fatigue, and status material details

Keep the silhouette chicken-like. Human accessories are funniest when they are slightly awkward rather than when the birds become fully anthropomorphic people with chicken heads.

### Animation Set

The first shared animation library should include:

- Idle
- Walk or waddle
- Sit
- Stand
- Peck keyboard
- Read screen
- Talk or cluck
- Drink
- Eat
- Lay egg
- Carry egg
- Inspect or stamp egg
- Celebrate
- Look nervous
- Argue
- Exhausted slump
- Burnout or shutdown

Animations need broad, readable poses that work from an elevated camera. Subtle realism will be lost at management-game scale.

### Export Rules

- Export through glTF/GLB.
- Apply transforms before export.
- Use consistent real-world scale.
- Use clear, stable object and bone names.
- Keep origins deliberate and consistent.
- Separate reusable meshes from scene-specific decoration.
- Prefer primitive collision shapes authored in Godot.
- Keep materials reusable across the office kit.
- Pack texture channels where appropriate and use compressed textures in exported builds.
- Test representative assets in Godot early rather than completing the whole Blender library first.

### Visual Budget

Use stylized low- to mid-poly assets with strong shape language. Repeated furniture should share meshes and materials. Small clutter can be instanced, combined, or selectively disabled at distant zoom levels.

The visual target is “deliberately crafted corporate diorama,” not photorealism.

---

## Audio Direction

The office should sound like a machine made from chickens and bureaucracy:

- Pecking blends with keyboard clatter.
- Clucks resemble overheard office conversation.
- Printers, phones, ventilation, and fluorescent hum create the workplace bed.
- Egg completion uses a satisfying but restrained sound.
- Farmer announcements are calm and friendly regardless of content.
- Increased stress introduces faster pecking, ringing phones, and mechanical noise.
- Moments of solidarity reduce office noise and bring back natural farm ambience.

Audio should help the player recognize operational problems before reading an alert.

---

## First Vertical Slice

### Scope

Build one in-game workweek containing:

- One office room
- Six hens
- One player-controlled rooster
- Eight workstations
- One nesting area
- One break area
- One incoming claim type
- Three egg outcomes: sound, cracked, and golden
- Four worker needs
- Five management policies
- Three major workplace events
- One farmer presentation
- Three end-of-week outcomes

### Required Systems

- Orthographic camera controls
- Chicken selection and inspection
- Work assignment
- Central simulation tick and time controls
- Basic needs and productivity
- Claim-to-egg production flow
- Revenue and expense tracking
- Office furniture placement or predefined rearrangement
- Simple navigation and shared animations
- Policy decisions
- Delayed errors and rework
- End-of-week presentation
- Save and load

### Suggested Events

- Mandatory Fun Friday
- The Golden Egg
- Flock Restructuring

### Prototype Success Criteria

The vertical slice succeeds if players:

- Enjoy watching claims become eggs.
- Understand why output changes.
- Care about at least one individual chicken.
- Make at least one uncomfortable optimization choice.
- Laugh when the farmer misrepresents their work.
- Want to replay the week using a different management philosophy.

---

## Development Order

### Phase 1: Paper Economy

Implement the simulation without final 3D assets. Use simple data, debug panels, and automated tests to validate work queues, needs, egg outcomes, delayed consequences, and daily accounting.

### Phase 2: Graybox Office

Create a Godot office from primitive meshes. Add camera control, selection, workstation interaction points, navigation, and placeholder chickens.

### Phase 3: Visible Production

Connect simulation intentions to movement and animation. Make claims, pecking, nests, eggs, inspection, and collection visually understandable.

### Phase 4: First Decisions

Add policies, worker relationships, the three major events, and the farmer presentation. Test whether the satire emerges from choices rather than explanation.

### Phase 5: Blender Art Pass

Replace graybox assets with a small modular office kit and the first rigged chicken. Validate the complete Blender-to-Godot process before producing variations.

### Phase 6: Balance and Polish

Tune the workweek, improve feedback, add audio, refine UI, and test multiple play styles. Only expand the office after the first department is consistently enjoyable.

---

## Major Risks and Mitigations

### Risk: The Game Becomes an Idle Waiting Simulator

**Mitigation:** Front-load staffing, routing, layout, and policy decisions. Give the player quick early outcomes and useful speed controls.

### Risk: The Chickens Become Anonymous Units

**Mitigation:** Keep the first team small, make traits consequential, use names and distinct accessories, and generate relationship-driven incidents.

### Risk: Too Much Micromanagement

**Mitigation:** Allow schedule templates, batch assignments, supervisors, and automation. Preserve direct intervention for unusual or morally significant decisions.

### Risk: The Economy Has an Obvious Best Strategy

**Mitigation:** Use delayed consequences, changing farmer priorities, nonlinear costs, and interacting resources. Record balance data and compare different player strategies.

### Risk: 3D Art Delays Gameplay Development

**Mitigation:** Build the economy and graybox office first. Establish a validated modular pipeline with one desk, one chicken, one animation, and one interaction before producing the full asset set.

### Risk: Pathfinding Breaks the Business Simulation

**Mitigation:** Keep economic intent authoritative and visible navigation recoverable. A presentation problem should not permanently corrupt production state.

### Risk: The Satire Feels Preachy

**Mitigation:** Let incentives, consequences, visual details, and management language communicate the argument. Give characters understandable motives and avoid explaining every joke.

### Risk: The Dark Material Overwhelms the Comedy

**Mitigation:** Preserve friendships, personal decoration, worker humor, and small victories. Warmth gives the darker systems emotional weight.

---

## Decisions to Lock Before Full Production

- The player begins as a rooster managing a single department.
- The first release targets desktop.
- The office uses stylized 3D and an orthographic camera.
- The first campaign focuses on insurance claims.
- The authoritative simulation is separate from 3D character nodes.
- The first team remains small enough for every chicken to be recognizable.
- Office construction begins as constrained furniture placement rather than unrestricted architecture.
- Multiplayer and procedural office generation are outside the initial scope.

---

## Development North Star

Every major system should satisfy three questions:

1. Is it satisfying to operate and optimize?
2. Can the player see its effect on individual chickens?
3. Does it reveal who receives the benefit and who carries the cost?

If a feature only makes a number larger, it needs a consequence, a character response, or a visible journey through the office.

The ideal moment is when the player watches a hen produce an excellent egg, feels proud of improving the workflow, and then sees the farmer present that egg as proof of his own leadership.
