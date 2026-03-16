# Physical Realism For Image-to-Video

Use these rules when the goal is believable product motion instead of flashy but unstable animation.

These notes are distilled from official video prompting docs and adapted for this skill's Seedance workflow.

## Core Rules

### 1. Let the image define appearance; let the prompt define motion

For image-to-video, do not spend most of the prompt re-describing the whole image.
Use the prompt mainly to specify:

- camera movement
- subject movement
- environment movement
- temporal order

This matches official guidance from Runway's image-to-video docs.

### 2. Keep motion simple, local, and physically plausible

Prefer:

- slight push-in
- slow orbit
- gentle hand motion
- wind moving leaves or hair
- liquid flowing downward
- condensation sliding
- slow rotation with visible support

Avoid combining too many simultaneous changes in one short clip.

### 3. Match event complexity to duration

If the clip is short, ask for one clear scene with one primary action.
Do not force multiple scene transformations into a single image-to-video clip.

### 4. Use positive preservation language

When you want stability, say:

- keep the lighting consistent
- keep the background stable
- keep the subject proportions consistent
- keep the hand-to-product relationship stable

Avoid heavy negative prompting.

### 5. Respect material behavior

Write motion that fits the material:

- fruit: slight sway, subtle rotation, dew, gentle bounce only if supported
- liquid: flow, drip, gather, pour, splash with gravity
- glass: reflective highlights, small tilt, stable rigid body motion
- metal: crisp reflections, rigid motion, no soft deformation
- paper/label: small flutter only if wind is present
- skin/hand: stable grip, natural finger motion, no sudden distortion

### 6. Prefer anchored spatial relationships

If the source image already has a strong composition, keep:

- background depth order
- object scale
- lighting direction
- hand/object contact points

### 7. One camera move is usually enough

For product ads, one of these is often sufficient:

- slow push-in
- subtle pull-back
- gentle orbit
- slight handheld drift
- low-angle tilt up

Using too many camera moves often causes incoherent motion.

## Product-Specific Heuristics

### Handheld products

If a hand is holding the product:

- the grip should remain stable
- the product should not teleport or spin unnaturally
- finger position should only change slightly
- the camera should move more than the hand

### Fruit / fresh produce

Prefer:

- dew shimmering
- leaves moving in wind
- sunlight changing softly
- fruit rotating slightly in place

Avoid:

- fruit exploding into abstract particles unless clearly stylized
- impossible hovering without support
- dramatic morphing of the fruit shape

### Juice / original extract

Prefer:

- droplets forming and falling with gravity
- liquid gathering in a coherent direction
- smooth reflective highlights
- one clean transformation from fruit detail to liquid detail
- liquid entering the cup only through the visible opening
- liquid level rising only inside the container
- container bottom and walls staying fully intact and sealed

Avoid:

- chaotic multi-direction splashes
- liquid appearing from nowhere without visual cause
- liquid leaking through the bottom or side wall of a cup
- liquid intersecting with glass geometry or passing through a solid container
- cup shapes deforming while pouring unless deformation exists in the source image

## Short Prompting Checklist

Before finalizing the prompt, check:

- Is there only one main action?
- Does the motion obey gravity and material properties?
- Is the background stable enough?
- Is the camera move simple enough?
- Does the prompt ask for continuity instead of transformation overload?

## Source Notes

Official references used for these rules:

- Runway Image to Video Prompting Guide: https://help.runwayml.com/hc/en-us/articles/48324313115155
- Runway Gen-4 Video Prompting Guide: https://help.runwayml.com/hc/en-us/articles/39789879462419-Gen-4-Video-Prompting-Guide
- Runway Gen-3 Alpha Prompting Guide: https://help.runwayml.com/hc/en-us/articles/30586818553107-Gen-3-Alpha-Prompting-Guide
- Runway Aleph Prompting Guide: https://help.runwayml.com/hc/en-us/articles/43277392678803
- Luma Dream Machine Video Generation docs: https://docs.lumalabs.ai/docs/video-generation
