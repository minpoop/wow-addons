# James Sunderland portrait

`JamesSunderland.png` is an original AI-generated fan-art illustration created for
ForeverXP, depicting James Sunderland from Silent Hill 2. It is not an extracted
game texture, screenshot or promotional image. The original companion notes are
separate from the illustration and do not quote game dialogue.

The runtime uses a 256 × 256, opaque, uncompressed 24-bit TGA for a 128 × 128
portrait panel. Re-export from this source using ImageMagick:

```sh
magick art/JamesSunderland.png -resize 256x256 -alpha off -depth 8 -compress None ForeverXP/Assets/JamesSunderland.tga
```

The package includes the TGA, not this full-resolution source. Live texture loading
on the target client remains unverified. `tools/preview.py` reads the actual TGA
and converts it to PNG for the source-rendered browser preview.
