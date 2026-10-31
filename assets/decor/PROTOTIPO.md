# Fondos botánicos de Lumi

Recursos originales creados con la herramienta integrada **imagegen**, a partir de una descripción del estilo del prototipo del usuario. El prototipo se usa como orientación visual; no se ha recortado para convertir sus textos o controles en imágenes.

- `lumi-sidebar-botanico-v1.png`: fondo de navegación con cintas y hojas en los bordes.
- `lumi-panel-botanico-v1.png`: fondo del panel principal, con espacio oscuro para contenido y ondas inferiores.
- `lumi-inspector-botanico-v1.png`: fondo del inspector con botánica concentrada abajo.
- `lumi-flor-cabecera-v1.png`: ilustración de hojas y cintas para la cabecera.

Las imágenes y sus opacidades se integran con ImageLabel pasivos desde `src/Artwork.luau` y `src/components/BrandArt.luau`. Los controles siguen siendo nativos y funcionales.

## Prompts de generación

### sidebar-botanico

```text
Use case: stylized-concept. Asset type: production background texture for a narrow vertical warm dark GUI sidebar, Lumi. Make a portrait 1:3 illustration, ideally 512x1536. This is ONLY the background image, absolutely NO text, letters, logos, icons, buttons, panel outlines, borders, screenshots or UI controls. Full-bleed opaque deep espresso-brown base (#30231c, #392a21, #261e19) with exceptionally subtle warm lighting depth, smooth and refined with no noisy grain. Elegant botanical ribbon motifs: in the bottom 42 percent, broad translucent-looking taupe and caramel curved ribbons sweep upward from the lower left and curl toward the lower right, with three graceful pointed warm-beige leaves on a fine curved stem along the lower right edge and a small ivory four-point sparkle near the bottom left. An extremely subdued narrow ribbon sweep in the top fifth, around 18 percent height, leaving the upper 0-15 percent very clear for a logo and the middle 25-60 percent clear for navigation text. The ornaments should occupy the edges, be partially cropped by the frame and use muted sand #987354 and honey #C39B75 at restrained contrast. Calm luxurious botanical editorial illustration; soft flat shaded planes rather than glossy chrome. Match a warm dark cocoa interface with ivory typography. The background must remain dark enough for readable text. No bright gold glows, no neon, no bloom, no particles, no stars scattered everywhere, no drop shadow outside image.
```

### panel-botanico

```text
Use case: stylized-concept. Asset type: production full-panel background image for Lumi warm dark graphical interface. Create a square full-bleed opaque image, ideally 1024x1024. Background only: NO text, letters, logos, UI elements, buttons, controls, frames or borders. Rich dark espresso/cocoa base (#33261f near top, #291f1a in center, #3c2d23 toward bottom) with gentle smooth broad warm illumination and depth, no noisy grain or speckled texture. Keep the top 85 percent nearly empty, elegant and dark, with only extremely subdued sweeping tonal curves at the far right edge. At the very bottom 12 percent, flowing champagne-beige and muted caramel satin-paper ribbons sweep along the bottom edge from the lower left corner and taper toward the lower right; a tiny warm ivory concave four-point sparkle sits near bottom center. Restrained botanical editorial aesthetic, broad clean tapered curves, soft folded planes, fine graceful arcs, calm and premium. The left and central regions must have ample dark negative space for real interactive content drawn later. Ornamental color #AC8765 with a few ivory #E5C7A5 folded highlights only at the extreme lower edge. No 3D mockup, no external shadows, no glow, no neon, no glitter, no human or character.
```

### inspector-botanico

```text
Use case: stylized-concept. Asset type: production full-height background for Lumi's narrow inspector pane, portrait 1:3 composition ideally 512x1536. ONLY a background image with no text, no typography, no logo, no icons, no controls, no panels, no border. Opaque full-bleed very dark warm coffee base #30231c with slight soft shaded depth from #3C2C22 to #261E19. Main top 75 percent largely clear and dark for ivory labels and controls. At the bottom 20 percent, elegant wide muted taupe/caramel ribbons rise in a low broad arc from lower left to lower right, curling into the bottom right corner. Three small pointed botanical leaves on a graceful stem rise from that lower right curl, reaching only to 78 percent height. In the extreme top right 5-7 percent, a tiny ivory four-point star and a faint short curved flourish; leave the upper left clear. Motifs cropped at the lower edges, refined softly shaded paper-satin illustration, muted sand #987354 and caramel #B28A66, sparse creamy highlights. All decoration soft and low contrast against the cocoa field, legible background, no particles, no glow, no chrome, no neon, no gradient rainbow, no UI screenshot.
```

### flor-cabecera

```text
Use case: stylized-concept. Asset type: original transparent PNG botanical flourish for the right-hand corner of a warm dark Lumi interface header. A graceful small arrangement of three pointed folded ivory/beige leaves, two slender stems and broad tapering honey-caramel ribbons that curl upward along the right edge and sweep low toward the left. One small concave four-point ivory sparkle above the leaves. Clean sophisticated botanical editorial illustration, with soft shaded papery folded planes. Palette: warm ivory #F5DFC5, muted sand #BA9371, cocoa-taupe #806047, honey #D1A77D. Landscape 3:2 composition. Occupy the right half most densely with the leaves; extend one fine low ribbon arc into the lower left, tapering to nothing. Keep a little transparent breathing room, no rectangular background or baked shadow. This must read elegantly at roughly 200x118 pixels on an espresso #30231C surface. Genuine transparent alpha between all shapes. No text, no letters, no logo, no border, no frame, no UI controls or mockup, no glow, no glitter, no neon, no childish objects, no busy scattering. Delicate but substantial silhouette, calm premium warm brand identity.
```

## Ajustes de imagen utilizados

### flor-cabecera-limpia

```text
Edit this botanical flourish asset for a dark cocoa GUI. Preserve the exact three leaves, their stems, four-point star and ribbon shapes and their warm ivory/sand colors. REMOVE ALL the surrounding golden haze, glow, halos, mist and background. Everything outside the leaf/ribbon/star silhouettes, including the spaces between them, must be genuinely transparent alpha with clean antialiased cutout edges. No blurred shadow or ambient light outside the artwork. Do not add text, panels, borders or controls. Keep the original composition and proportions. Deliver an isolated transparent PNG cutout, with no opaque black or brown background.
```

### inspector-botanico-bajo

```text
Edit this tall dark coffee background for a GUI inspector. Keep the same dark cocoa surface color and smooth lighting, the small top-right star, and the fine top-right flourish. Scale down and reposition the ENTIRE lower botanical arrangement (all three leaves, stems and bottom ribbons) so it occupies ONLY the bottom 20 percent of the image. The tallest leaf tip must be BELOW 80 percent of the full image height. Everything from 10 through 80 percent height must remain an empty dark coffee field for readable UI properties. Make the lower ribbons and leaves muted warm taupe, less bright, restrained, low contrast with the cocoa background. Keep their elegant curved botanical character. No text, no controls, no frames, no borders. Full-bleed opaque portrait background. Preserve the narrow tall aspect ratio.
```
