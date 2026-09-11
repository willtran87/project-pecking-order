# Opening cast dialogue cutouts — generation record

Mode: OpenAI built-in image generation. Mabel was generated first and explicitly
approved as the visual lock; every later portrait used that approved image as its
style reference.

Shared prompt contract:

> Create a high-resolution, hand-pixeled isometric dialogue cutout for Pecking
> Order, a cozy but dark corporate-insurance satire starring chickens. Match the
> approved Mabel portrait's pixel density, warm muted palette, soft readable
> clusters, three-quarter pose, expressive face, and charming late-1990s
> management-game character art. The chicken must be puffy, anatomically
> connected, and cohesive: head, face, comb, neck, body, wings, feet, clothing,
> and accessories must touch naturally with no floating pieces. Use a flat
> chroma-key background for clean alpha extraction. No border, speech balloon,
> caption, logo, watermark, or UI.

Character deltas:

- Mabel — hopeful but anxious cream hen, Appeals worker, narrow blue tie and
  employee badge; earnest posture and a slightly overfull claims folder.
- Pip — skeptical, composed white-and-brown hen, quiet Nest Damage professional,
  round spectacles and restrained green tie; meticulous paperwork.
- Henrietta — warm russet hen, tired and quietly anxious Predator Loss nester,
  cozy teal cardigan and soft collar; protective, rounded posture.
- Dot — dark speckled hen, knowing social expression, Nest Damage networker, red
  bow tie and gold glasses; office mug and discreet gossip energy.
- Cornelius Claimwell — weary cream-and-russet rooster, Credit Manager, attached
  comb, charcoal vest and tie, clipboard; managerial posture under cold vent
  light, sympathetic middle-management fatigue rather than villainy.

Runtime preparation:

- Chroma backgrounds were removed to alpha.
- Portrait source files were normalized to exact 1024×1024 RGBA canvases.
- Godot runtime imports are capped at 512×512; the largest on-screen portrait is
  178×188, so this retains crisp oversampling while reducing Web texture memory.
- Runtime resizing used nearest-neighbor sampling.
- Transparent corners and green-edge contamination were checked for all five.
- These assets remain `source-reference-pass`: portrait cutouts only, with no
  implied action-frame or production-animation completeness.
