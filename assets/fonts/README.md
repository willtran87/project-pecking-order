# Office type palette

The in-world office props use three SIL Open Font License 1.1 families from
the Google Fonts repository:

- Barlow Condensed (regular and semibold) for institutional signs, room
  identities, engraved plates, and raised equipment lettering.
- IBM Plex Mono (regular and semibold) for live ledgers and machine screens.
- Courier Prime (regular and bold) for forms, notices, stamps, and receipts.

Upstream sources:

- https://github.com/google/fonts/tree/main/ofl/barlowcondensed
- https://github.com/google/fonts/tree/main/ofl/ibmplexmono
- https://github.com/google/fonts/tree/main/ofl/courierprime

The font binaries use the deliberately non-imported `.fontbytes` extension and
are loaded into `FontFile` resources at runtime. This avoids editor-only import
state and keeps native and Web exports on the exact same authored files. Each
family is distributed under the license included in its corresponding
`OFL-*.txt` file in this directory.
