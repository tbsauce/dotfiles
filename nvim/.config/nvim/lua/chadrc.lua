-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "catppuccin",

	-- Override base46's catppuccin (Mocha) with Macchiato palette
	changed_themes = {
		catppuccin = {
			base_30 = {
				white = "#cad3f5",
				darker_black = "#1e2030",
				black = "#24273a",
				black2 = "#2b2e42",
				one_bg = "#363a4f",
				one_bg2 = "#3f4358",
				one_bg3 = "#474b60",
				grey = "#505469",
				grey_fg = "#575b70",
				grey_fg2 = "#5e6277",
				light_grey = "#6e738d",
				red = "#ed8796",
				baby_pink = "#f5bde6",
				pink = "#f5bde6",
				line = "#414559",
				green = "#a6da95",
				vibrant_green = "#b1e5a0",
				nord_blue = "#91b4f6",
				blue = "#8aadf4",
				yellow = "#eed49f",
				sun = "#f4daa5",
				purple = "#c6a0f6",
				dark_purple = "#b694ea",
				teal = "#8bd5ca",
				orange = "#f5a97f",
				cyan = "#91d7e3",
				statusline_bg = "#292c3c",
				lightbg = "#363a4f",
				pmenu_bg = "#a6da95",
				folder_bg = "#8aadf4",
				lavender = "#b7bdf8",
			},

			base_16 = {
				base00 = "#24273a",
				base01 = "#2e3148",
				base02 = "#363a4f",
				base03 = "#414559",
				base04 = "#494d64",
				base05 = "#b8c0e0",
				base06 = "#c1c9e6",
				base07 = "#cad3f5",
				base08 = "#ed8796",
				base09 = "#f5a97f",
				base0A = "#eed49f",
				base0B = "#a6da95",
				base0C = "#91d7e3",
				base0D = "#8aadf4",
				base0E = "#c6a0f6",
				base0F = "#ed8796",
			},
		},
	},

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
