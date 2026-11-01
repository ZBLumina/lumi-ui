# Ilustraciones de Lumi

PNG originales creados con la herramienta integrada **imagegen** para la decoración de Lumi UI. Los archivos conservan la transparencia generada. Las imágenes de referencia del usuario no se han integrado en estos recursos.

- `lumi-orbita-v1.png`: cintas marfil y miel con destellos; cabecera.
- `lumi-onda-v1.png`: onda horizontal; separadores de navegación e inspector.

Las fuentes utilizadas por la interfaz están centralizadas en `src/Artwork.luau`. Los archivos se cargan desde GitHub y se guardan en la caché local del ejecutor.

## Prompts utilizados

### Órbita

```text
Use case: stylized-concept. Asset type: production decorative PNG illustration for Lumi, a refined warm dark graphical interface. Create ONE original elegant emblem made of two flowing ivory and muted honey satin-paper ribbons sweeping around a small concave four-point star, with one very small secondary star. The ribbons should have broad beautiful tapered silhouettes, soft warm peach folded undersides, extremely restrained shaded dimension like premium editorial illustration. Palette: ivory #FFF1DF, pale honey #EBC496, sand #C4AD94, peach #D5A77D. This will appear at only 152 by 88 pixels on dark coffee #241E1A, so keep the shapes clean, bold enough to read at small size and uncrowded. Landscape composition 3:2, isolated, centered, tightly framed with 5 percent clear padding. Transparent background with real alpha, no background-colored rectangle, no shadow outside the motif. Not a UI mockup: only the decorative illustration, no panel, no text, no letters, no logo, no watermark. Sophisticated calm brand identity, no neon, no bloom, no glitter particles, no chrome, no rainbow, no childish characters. The ribbons and stars form a balanced gently rising orbital sweep. Deliver a high-quality transparent PNG.
```

### Onda

```text
Use case: stylized-concept. Asset type: transparent horizontal ornamental ribbon divider for Lumi, a sophisticated dark coffee graphical interface. Create ONE original very wide low flowing flourish: two graceful, broad, tapering ivory and pale honey paper-satin ribbons following a smooth shallow S curve, with a delicate third fine ivory line echoing the flow. Long sweeping arcs, a single subtle folded peach underside near the right third. Palette ivory #FFF1DF, pale honey #EBC496, muted peach #D5A77D. Refined warm editorial brand illustration with softly shaded planes, very clean edges and no texture noise. The visual will be reduced to a divider about 144 by 26 pixels; keep it simple and horizontally stretched, not a complex emblem. 3:1 landscape composition, flowing from left edge to right edge, minimal vertical amplitude; isolated on true transparent alpha, with transparent spaces between the ribbons and no painted background. No stars, no text, no logos, no frame, no UI mockup, no glow, no shadow behind the artwork, no glitter, no neon. Only this one long ribbon flourish. Deliver a high quality transparent PNG.
```
