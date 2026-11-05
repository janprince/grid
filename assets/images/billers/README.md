# Biller marks

Drop the nine biller logos here as PNG or WebP on a transparent ground, ~144px square
(3x of the 48px mark). Filenames are matched exactly by `BillerBrand` in
`lib/core/theme/biller_brand.dart`:

    ecg.webp       Electricity Company of Ghana (supplied logo)
    gwcl.png       Ghana Water Company Ltd
    dstv.png       DStv
    gotv.png       GOtv
    startimes.png  StarTimes
    mtn.png        MTN (airtime + data)
    telecel.png    Telecel
    at.png         AT
    surfline.png   Surfline / fibre

Until a file is present, `BillerMark` renders a coded fallback: the utility's
Material glyph on the biller's brand colour. The app is fully functional with
this directory empty — add marks incrementally and each one lights up on its own.
