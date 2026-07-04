**This version is for OpenMW dev builds.** See https://github.com/wareya/OpenMW-PBR/releases for OpenMW stable/release builds.

This repository is not associated with OpenMW

# Wareya's PBR shaders for OpenMW 0.52

| PBR | Vanilla |
|-----|---------|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-25-56" src="https://github.com/user-attachments/assets/d0a7d51e-754b-4afd-b26c-040a91a64879" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-25-53" src="https://github.com/user-attachments/assets/ad80784a-4445-49b1-aa0a-b47cc87089de" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-28-05" src="https://github.com/user-attachments/assets/480b1982-de49-4fcc-be18-4f01141099cf" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-28-03" src="https://github.com/user-attachments/assets/353596eb-af99-48a4-8e39-d84ebf99a855" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-34-12" src="https://github.com/user-attachments/assets/e7a1616b-cc51-488f-a937-57ea363ed879" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-34-16" src="https://github.com/user-attachments/assets/878ef212-bde5-4a06-a66d-d8dc0a1cbe6f" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-37-11" src="https://github.com/user-attachments/assets/ade07acf-a18b-40d9-95f0-6b33cd125aa8" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-37-15" src="https://github.com/user-attachments/assets/ec54beae-9de3-46f4-b7c2-013181517227" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-41-10" src="https://github.com/user-attachments/assets/d7884585-8973-4e59-93fc-04d49356cf96" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-41-14" src="https://github.com/user-attachments/assets/95d98b21-2a1d-4a9c-a741-e115dbdc69a9" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-43-58" src="https://github.com/user-attachments/assets/53383643-9dae-4dc9-a8ed-707783bf5710" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-44-03" src="https://github.com/user-attachments/assets/29f8a6f3-8fcc-410b-9c14-d60f6344d25f" />|
|<img width="1920" height="1080" alt="openmw_2026-07-04_17-45-54" src="https://github.com/user-attachments/assets/b840d882-c29f-4eff-a893-c3f38decf25c" />|<img width="1920" height="1080" alt="openmw_2026-07-04_17-45-57" src="https://github.com/user-attachments/assets/65ad2483-e058-40e1-b744-c4a362b38bf2" />|

(screenshots taken with other mods also installed)

Minimally invasive PBR shaders for OpenMW. Don't install unless you know what you're doing. Make a backup of the vanilla shaders folder by COPYING it (NOT by renaming it), then copy these shaders over the base ones (DO NOT try to install this over another core shader mod! IT WILL NOT WORK!!!).

Implements modern PBR. Highly configurable. Lighting math is done in (approximately) linear light. Configuration is in lighting_pbr.glsl.

These shaders attempt to automatically generate roughness data if there's no PBR specularity material available. To disable this, set `PBR_AUTO_ROUGHNESS_MIN` and `PBR_AUTO_ROUGHNESS_MAX` to the same value (0.75 for example).

Supports PBR specular materials. Red: metal, green: roughness, blue: ambient occlusion. If you want to use PBR materials where green is smoothness instead of roughness, change `PBR_MAT_ROUGHNESS_INVERTED 0` to `PBR_MAT_ROUGHNESS_INVERTED 1`.

Make sure you have these settings set in settings.cfg to avoid any possible issues:

```
force shaders = true
clamp lighting = false
force per pixel lighting = true
```

## License

Licensed under the GNU GPL v3. See LICENSE and AUTHORS.md for more information. AUTHORS.md contains a list of contributors to OpenMW, only some of which have contributed to the shader code that these shaders are based on.

