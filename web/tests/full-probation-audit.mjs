// Cross-platform release preset for the complete authored probation arc.
// The shorter audit keeps tighter two-shift residency budgets; a full file can
// legitimately add two staffed hens and their connected presentation objects.
process.env.ACTIVE_PROGRESSION_SHIFTS ??= "5";
process.env.ACTIVE_PROGRESSION_MAX_MSEC ??= "900000";
process.env.ACTIVE_PROGRESSION_WASM_GROWTH_BYTES ??= String(96 * 1024 * 1024);
process.env.ACTIVE_PROGRESSION_OBJECT_GROWTH ??= "1536";
process.env.ACTIVE_PROGRESSION_NODE_GROWTH ??= "192";

await import("./active-progression-audit.mjs");
