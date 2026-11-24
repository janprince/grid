# Service artwork

## 3D renders (`3d/`)

One 3D object render for each service and for each package group. This is the
artwork for service tiles, shortcut rows, lists and package cards. It replaces
the Fluent emoji icons in `icons/`.

The same files are in `GRID PRO/assets/images/services/3d/`. Keep the two
folders identical.

### Format

- 512 × 512 PNG, opaque, no alpha.
- The background is baked in: flat warm off-white `#F7F3EC` (±2 per channel).
  Show the image as the tile itself, clipped to the tile's corner radius, or
  on a `#F7F3EC` surface. On any other colour the square edge shows.
- One object, centred, filling about 65–75% of the frame, with a soft contact
  shadow. No people, text or logos. Navy `#13294B` and amber `#F4C76A` accents.

### Files

Services are named by category slug. Packages are named
`<category>-<group>`, the start of the API package slug in
`Grid.API/src/Grid.Api/Features/Catalogue/CatalogueSeed.cs`. The size variants
of a package share one image.

| File | Shows | API package slugs |
|---|---|---|
| `cleaning.png` | Spray bottle, cloth, bubbles | category `cleaning` |
| `laundry.png` | Folded towels in a woven basket | category `laundry` |
| `ac-servicing.png` | Split AC unit with airflow | category `ac-servicing` |
| `pest-control.png` | Pump sprayer and shield | category `pest-control` |
| `plumbing.png` | Wrench across a pipe elbow | category `plumbing` |
| `electrical.png` | Light bulb and wall switch | category `electrical` |
| `cleaning-standard.png` | Cleaning caddy | `cleaning-standard-{1..4}-bed` |
| `cleaning-deep.png` | Scrub brush and foamy sponge | `cleaning-deep-{1..4}-bed` |
| `cleaning-move.png` | Moving box and broom | `cleaning-move-{1..4}-bed` |
| `cleaning-sofa.png` | Two-seat sofa with bubbles | `cleaning-sofa-seat` |
| `laundry-wash-fold.png` | Stack of folded clothes | `laundry-wash-fold` |
| `laundry-wash-iron.png` | Steam iron on a folded shirt | `laundry-wash-iron` |
| `laundry-duvet.png` | Folded duvet and pillow | `laundry-duvet` |
| `laundry-dry-clean.png` | Suit jacket in a garment bag | `laundry-dry-clean-suit` |
| `ac-servicing-general-service.png` | AC unit, toolbox, screwdriver | `ac-servicing-general-service` |
| `ac-servicing-deep-foam.png` | Open AC unit with foam on the coil | `ac-servicing-deep-foam` |
| `ac-servicing-gas-top-up.png` | Gas cylinder and pressure gauge | `ac-servicing-gas-top-up` |
| `ac-servicing-not-cooling.png` | AC unit under a magnifying glass | `ac-servicing-not-cooling` |
| `pest-control-fumigation.png` | Fogger with mist | `pest-control-fumigation-{small,large,xl}` |
| `pest-control-rodents.png` | Bait box and cheese | `pest-control-rodents` |
| `pest-control-termite-inspection.png` | Wood plank under a magnifying glass | `pest-control-termite-inspection` |
| `plumbing-call-out.png` | Dripping tap and toolbox | `plumbing-call-out` |
| `electrical-call-out.png` | Multimeter with probes | `electrical-call-out` |

A package without its own image should fall back to its category's image.

### How it was made, and adding one

The full guide is
[`DOCUMENTATION/service-artwork.md`](../../../../DOCUMENTATION/service-artwork.md).
It covers the style rules, the exact prompt and model, the post-processing
script, the Figma file, and how to add a render that matches. It also indexes
every render, including the 48-render library of future services in
`DOCUMENTATION/service-artwork/library/`. Library renders are not in the apps.

## Legacy icons (`icons/`)

`icons/` holds the earlier Fluent Emoji 3D icons
(<https://github.com/microsoft/fluentui-emoji>, MIT licence in
`icons/LICENSE`). The 3D renders above replace them. The files stay until no
code refers to them. Keep `LICENSE` with them while they ship.

## Photographs

One landscape photograph per service, 3:2, at least 600px wide, shown at the
top of the service's own page. Keep the person and their work near the
centre, because the frame crops the photograph.

| File | Service |
|---|---|
| `cleaning.jpg` | Home cleaning |
| `plumbing.jpg` | Plumbing |
| `ac_repair.jpg` | AC servicing |
| `electrical.jpg` | Electrical |
| `carpentry.jpg` | Not offered yet |

Confirm the licence for each photograph before public launch.
