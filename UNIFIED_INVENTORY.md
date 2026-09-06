# Unified EUROGRAD inventory

This branch contains the grid inventory, Z-City equipment preview and the
Moodles status presentation in the EUROGRAD repository. The separate
`zcity_case_inventory` and Workshop item `3683079310` are not required for this
screen.

## Changing the name and theme

Edit `lua/playercase/client/cl_theme.lua`. It contains:

- the two-part brand name shown in the top-left corner;
- the fallback character role and every section label;
- the interface and character-name fonts;
- all primary, secondary, panel and status colours.

The file is loaded before the inventory renderer, so no other UI file needs to
be edited when creating another theme.

## Controls

- `I`: open or close inventory;
- right mouse button: item context options;
- `R`: rotate a selected item.

## Included integrations

- live Z-City organism state and temperature;
- Moodle icon, severity and description rows;
- body-part damage monitor;
- Z-City sling, flashlight, head armour and torso armour slots;
- armour/accessory rendering on the character preview.
