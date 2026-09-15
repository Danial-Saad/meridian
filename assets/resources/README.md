# Put your resource/course images here

Any image you drop in this folder is available to reference from
`lib/resources_config.dart` as `'assets/resources/<filename>'`.

- PNG or JPG both work fine.
- Roughly 16:9 works best — cards crop to that ratio with `BoxFit.cover`,
  so a very tall or very narrow source image will get cropped, not
  distorted (it never stretches).
- No required size — just don't go far below ~600px wide or it'll look
  soft when the card is large (e.g. tablet/desktop widths).
- If `lib/resources_config.dart` points at a filename that isn't here yet,
  the card shows a themed placeholder instead of crashing, so it's safe to
  write the config entry first and add the image after.

This file itself is just a placeholder so the folder isn't empty in the
zip — delete it whenever you want, it isn't referenced from any code.
