-- These are the settings.
-- showOutlines
-- hideTracer
-- enable og AT crosshair
-- crosshair full aim state color
-- crosshair not full aim state color
-- crosshair out of range color
-- crosshair out of boudns car color

  local function OnApply(self, val)
    self:resetLua()
  end

  local key_data = {
    key = Keyboard.KEY_LSHIFT, 
    name = "Change_Z_Level_Key", 
  }

  local category = "[Combat]";
  ModOptions:AddKeyBinding(category, key_data);
  
  local SETTINGS = {
    options_data = {
        showOutlines = {
            true,
            false,
            name = "IGUI_ATRO_showOutlines",
            tooltip = "IGUI_ATRO_showOutlines_tooltip",
            default = false,
            OnApplyMainMenu = OnApply,
        },
        hideTracer = {
            true,
            false,
            name = "IGUI_ATRO_hideTracer",
            tooltip = "IGUI_ATRO_hideTracer_tooltip",
            default = false,
            OnApplyMainMenu = OnApply,
        },
        enableOgCrosshair = {
            true,
            false,
            name = "IGUI_ATRO_enableOgCrosshair",
            tooltip = "IGUI_ATRO_enableOgCrosshair_tooltip",
            default = false,
            OnApplyMainMenu = OnApply,
        },
    },
    mod_id = 'Advanced_Trajectorys_Realistic_Overhaul',
    mod_shortname = 'ATRO',
    mod_fullname = 'Advanced Trajectorys Realistic Overhaul',
  }
  
  if ModOptions and ModOptions.getInstance then
    ModOptions:getInstance(SETTINGS)
  end