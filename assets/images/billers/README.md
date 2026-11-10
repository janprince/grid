# Biller marks

Each file is a 240px square WebP tile with the logo already on its ground.
`BillerMark` clips the corners, so tiles fill the square edge to edge. Filenames
are matched by `BillerBrand` in `lib/core/theme/biller_brand.dart`.

| File | Biller | Source |
|---|---|---|
| `ecg.webp` | Electricity Company of Ghana | Supplied logo |
| `gwcl.webp` | Ghana Water | GWCL app icon on the App Store (published by Afrifanom Limited) |
| `dstv.webp` | DStv | dstv.com site icon, on white |
| `gotv.webp` | GOtv | gotvafrica.com site icon, on white |
| `startimes.webp` | StarTimes | StarTimes ON app icon on the App Store |
| `mtn.webp` | MTN | mtn.com.gh SVG logo, on MTN yellow |
| `telecel.webp` | Telecel | telecel.com.gh site icon, on white |
| `at.webp` | AT | AT Mobile App icon on the App Store |

These are the billers' trademarks, used to identify who is being paid. Get each
biller's written permission before public launch.

Until a file is present, `BillerMark` shows the utility's glyph on the biller's
tint, so the app works with this directory empty.
