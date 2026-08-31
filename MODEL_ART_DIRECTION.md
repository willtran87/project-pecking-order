# Pecking Order Model Art Direction

## Target Look

The game should feel like **soft 1970s farm bureaucracy**: cozy, rounded chickens trapped inside a dusty insurance office. Characters should be appealing at first glance, while the props and presentation quietly reveal the darker corporate satire.

Use warm oat and cream feathers, dusty olive cubicles, ink-navy equipment, barn-red warnings, and egg-yolk accents. Large silhouettes carry the scene; small markings belong in materials and textures rather than extra floating geometry.

## Implementation Status

The first major art pass is now playable. The employee chicken has been rebuilt as a watertight 9,752-triangle character with a seven-bone armature, four authored actions, connected feather geometry, folded surface wings, and preserved feather material zones. The Feed Party is also physical: a Blender-authored galvanized trough, morale-pellet sacks, waterer, scoop, compliance plaque, and six exported attendance sockets appear in the wellness zone while the flock gathers and feeds.

## Highest-Priority Improvements

### 1. Rebuild the Chicken Silhouette

The initial primitive-based model has been replaced. Future revisions should refine the new silhouette without returning to disconnected detail.

- Create one intentional torso, neck, and head shell.
- Extrude folded wings from the body surface instead of attaching oval forms.
- Use a smaller centered wedge-shaped beak.
- Reduce cheek and wattle volume.
- Keep the breast round, the tail wedge-shaped, and the feet short and sturdy.
- Sculpt to find the form, then retopologize instead of shipping the voxel-remeshed topology.

Achieved: **9,752 triangles** for the complete visible employee chicken, including a 7,000-triangle watertight feather torso.

### 2. Add a Real Deformation Rig

The rebuilt model now includes a real seven-bone Blender armature. Godot plays the imported idle, walk, peck, and sit actions while retaining compatibility pivots for route and chair alignment.

Build a compact Blender armature with:

- Root and pelvis
- Chest and head
- Left and right folded-wing bones
- Two short leg chains
- Optional tail and breast squash bones

Weight one continuous body mesh to that armature, then author walk, sit, peck, type, breathe, blink, and lay animations in Blender. Export them to Godot as a `Skeleton3D` with `AnimationPlayer` or `AnimationTree` control.

### 3. Design for the Actual Isometric Scale

The eye, beak, wing, comb, and posture must remain readable when a chicken is only about **40–80 pixels tall**.

- Use a strong round body silhouette and a clear forward-facing beak.
- Exaggerate head bob, peck angle, and breathing slightly.
- Avoid detail smaller than a few screen pixels.
- Judge every revision in both a close-up turntable and the live office camera.

## Supporting Improvements

### Material Zoning

Keep a connected mesh while giving it two or three readable feather zones:

- Main feather color
- Lighter breast and face
- Darker folded wing and tail

Use vertex colors or multiple material surfaces on the same connected body. Suggested roughness: feathers 0.75–0.90, beak and feet 0.45–0.60, glossy eyes, and restrained screen emission.

### Interaction Sockets

Add named Blender empties to make animation alignment data-driven:

- `ChairSocket`
- `BeakTarget`
- `KeyboardTarget`
- `FootGround_L`
- `FootGround_R`
- `EggSocket`

Godot should align chairs, screens, feet, and eggs through these sockets instead of relying on hard-coded body lifts and desk offsets.

### Workstation Simplification

The current workstation has many separate objects and materials. Join parts by material and move keyboard keys, screen lines, memos, and drawer markings into an atlas.

Keep the large readable forms: chair, desk, monitor, claim tray, phone, mug, and drawers. Apply a consistent **2–4 cm rounded bevel** to hero-scale props and target roughly 6–10 material surfaces per workstation.

### Farm-Corporate Prop Kit

Replace generic office dressing with objects that reinforce the premise:

- Galvanized feed troughs
- Stamped **MORALE PELLETS** sacks
- Paper feed cones
- Nesting-box filing cabinets
- Egg-carton inboxes
- Barn-red compliance signs
- Poultry waterers in place of ordinary water coolers

The Feed Party is now a physical office event: a Blender-authored cart rolls into the wellness zone on four animated casters, settles with a restrained loose-grain burst, and gives each arriving chicken a varied physical feeding cue. Chickens path to six exported feeding sockets while management records attendance, and reduced-motion mode presents the same readable event without travel or particle motion.

### Lighting and Staging

- Add subtle ambient occlusion and contact shadows beneath birds and furniture.
- Use a warm key, cooler fill, and restrained rim light on chickens.
- Lower or cut away cubicle walls that hide faces.
- Reduce persistent status-label clutter so animation and silhouette carry more information.

## Acceptance Checks

- No disconnected feather islands or visibly floating accessories.
- Chickens read clearly as chickens at the normal isometric camera distance.
- Walking, sitting, pecking, and laying do not separate or clip body parts.
- Feet contact the floor and the torso contacts the chair naturally.
- The beak reaches the screen without the body entering the desk.
- Materials share one controlled palette across chickens, furniture, and farm props.
- Close-up quality does not come at the expense of web performance or game-scale readability.
