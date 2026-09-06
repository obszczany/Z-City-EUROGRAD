# EUROGRAD Workshop build log

This file is the persistent hand-off for maintainers and AI assistants. It
records what was requested, what each item contains, and how it is integrated.

## Integration policy

Third-party Workshop packages are managed with `resource.AddWorkshop` instead
of copying their Lua/assets into this public repository. This avoids silently
reuploading authors' work and makes updates traceable. EUROGRAD-owned adapters
(the execution prompt and Esc settings) live directly in this repository.

Gameplay dependencies are enabled by default. Compatibility, performance and
developer profiles are opt-in because they replace core camera/Lua/hook/render
behaviour and can conflict with one another. Their archived convars are listed
in the final section.

## Requested items

| Workshop ID | Addon | Audited contents | Build status / notes |
|---|---|---|---|
| 3782848810 | Manhunt Executions | 6 Lua, 4 model files, 21 sounds | Managed gameplay dependency. EUROGRAD adds its own red blinking behind-target `[E] EGZEKUCJA` prompt. Author text strongly objects to copying/reuploading. |
| 3793099213 | ZCity FPS & Stability Boost | 4 Lua; no assets | Managed gameplay dependency. Options added to EUROGRAD `Esc -> Settings -> Optimization`. Workshop page explicitly prohibits reuploading without permission. |
| 3785356208 | Viewfinder FIX | 1 Lua; no assets | Optional compatibility profile. Requires original Viewfinder `3780178294`, which was added to that profile. |
| 3767548087 | Door Knock // ZCity | 4 Lua, 1 sound | Managed gameplay dependency. Knock with `R` while aiming at a door. |
| 3737887777 | Z-City Bind Menu | 1 Lua | Managed gameplay dependency. Includes key-binding/help UI. |
| 3675753816 | ZCITY Clothing+ | 2 Lua, 155 model files, 106 material files | Managed gameplay dependency; large content pack. |
| 3690854231 | ZCITY Loadout Presets | 7 Lua, 1 material | Managed gameplay dependency. |
| 3721806933 | ZCity Explosive Vest | 1 Lua, 11 model files, 6 material files, 4 sounds | Managed gameplay dependency. **Yes, this contains content:** a compiled suicide-belt model (`vest.mdl` plus VTX/VVD/PHY), textures/icon and four MP3/OGG sounds. |
| 3701366943 | Colorable Clothes + Accessories | 2 Lua, 176 model files, 179 material files | Managed gameplay dependency; very large appearance content pack. |
| 3196355387 | Remove Voice Chat Icons | 1 Lua | Managed gameplay dependency; runs `mp_show_voice_icons 0`. |
| 1620875048 | Bucket's Optimizations | 1 Lua | Optional performance profile; changes/removes engine/gamemode hooks. |
| 2982286549 | Server & Client Optimization | 2 Lua | Optional performance profile; forces performance convars and removes effects/hooks. Do not combine blindly with every booster. |
| 2403043112 | Lua Patcher | 1 Lua | Developer profile only. Redefines Lua behaviour to mask/repair errors and can make debugging harder. |
| 3105962404 | Performant Render | 1 Lua | Optional performance profile; occlusion-query renderer for props/ragdolls/NPCs. |
| 793317003 | Widgets Disabler | 1 Lua | Optional performance profile. Workshop author currently labels it obsolete. |
| 3709219849 | Z-City Unconsciousness Meter | 2 Lua, 3 sounds | Managed gameplay dependency. |
| 3695822803 | Better Mapvote | 16 Lua, 2 sounds | Managed gameplay dependency; map voting, RTV and nominations. |
| 3695863063 | Improved Scoreboard | 4 Lua | Managed gameplay dependency; includes playtime tracking. |
| 3714182343 | Shootable Door Handles | 1 Lua, 1 sound | Managed gameplay dependency. |
| 3712846898 | Attach Anything | 1 Lua | Managed gameplay dependency; constraints for living entities. |
| 1762151370 | Improved FPS Booster | 14 Lua, 2 materials, 1 font/resource | Optional performance profile; has its own first-run UI and many saved graphics convars. |
| 682765484 | Addon hooks Lag Finder | 1 Lua | Developer profile only; temporarily wraps `hook.Add` and `net.Receive`. |
| 368857085 | Addon hooks Conflict Finder | 1 Lua | Developer profile only; temporarily wraps hooks to diagnose early returns. |
| 3737422346 | First Spawn Appearance Fix | 1 Lua | Managed gameplay dependency. Wraps the appearance network receiver. |
| 3740174900 | TTT Trap Activator SWEP | 5 Lua, 6 materials | Managed gameplay dependency; uses base/ZManip models rather than bundling a custom model. |
| 3757876289 | Drop&Kick (FIXED) | 5 Lua | Optional compatibility profile because it replaces major fake-camera/input hooks. |

## EUROGRAD-owned changes

- `lua/autorun/client/cl_eurograd_finisher_prompt.lua`: independently written
  availability detector, blinking red prompt and `[E]` input adapter for
  Manhunt Executions.
- `lua/initpost/menu-n-derma/derma/cl_menu_options.lua`: execution-prompt and
  player-render settings inside the native Esc options UI.
- `lua/playercase/client/cl_theme.lua`: `Fonts.Finisher` and `Colors.Finisher`
  control the new prompt's look.
- `lua/autorun/server/sv_eurograd_workshop_dependencies.lua`: Workshop delivery
  profiles.
- `build/workshop_ids.txt`: machine-readable installation list/grouping.

## Server profile convars

Set these in `server.cfg`, then restart the server:

- `eurograd_build_compatibility 1` enables Viewfinder + its fix and Drop&Kick;
- `eurograd_build_performance 1` enables all requested optimizer packages;
- `eurograd_build_developer_tools 1` enables Lua Patcher and hook diagnostics.

Leave them at `0` for the safer gameplay build. In particular, do not enable
all performance/developer packages on a production server without profiling.
