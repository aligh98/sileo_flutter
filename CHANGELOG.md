# Changelog

All notable changes to `sileo_glass` will be documented in this file.

## 0.1.0

- Initial Flutter port of `hiaaryan/sileo` with true `SpringSimulation` physics, velocity preservation, blur-crossfade header morphing, collapse-before-swap transitions, autopilot expand/collapse, hover/touch pause, vertical swipe-to-dismiss, and hit-test passthrough.
- 120Hz analytic gooey silhouette (`SileoSurfaceStyle.solid`, default) using C1-continuous cubic Bezier S-curves and circular quarter-arcs.
- Optional real-time GPU refractive Apple-style Liquid Glass (`SileoSurfaceStyle.liquidGlass`) powered by `liquid_glass_easy`'s single-pass `LiquidGlassBlender` metaball shader, with high-contrast iOS 26-inspired typography, semantic badges, and adaptive action buttons.
- First-class RTL mirroring, ambient font inheritance, and accessibility (`Semantics(liveRegion: true)` and reduced-motion support).
- Interactive Playground app (`example/`) featuring all 6 viewport positions, Morph/Stack mode, Solid/Liquid Glass toggle, Dark/Light theme, animated Flight Future card, and Persian RTL Vazirmatn showcase.
