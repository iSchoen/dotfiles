return {
	{
		name = "omarchy-theme",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		config = function()
			local theme_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
			local theme_name_file = vim.fn.expand("~/.config/omarchy/current/theme.name")
			local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

			-- Parse the Omarchy neovim.lua theme spec and apply the colorscheme
			local function apply_theme()
				if vim.fn.filereadable(theme_file) ~= 1 then
					return
				end

				-- Load the theme spec (returns a table of lazy.nvim-style entries)
				local ok, spec = pcall(dofile, theme_file)
				if not ok or type(spec) ~= "table" then
					return
				end

				local colorscheme = nil

				for _, entry in ipairs(spec) do
					if entry[1] == "LazyVim/LazyVim" and entry.opts and entry.opts.colorscheme then
						-- Extract the target colorscheme name
						colorscheme = entry.opts.colorscheme
					elseif entry[1] and entry[1] ~= "LazyVim/LazyVim" then
						-- Run theme-specific setup (e.g., catppuccin flavour, monokai-pro filter)
						local plugin_name = entry.name or entry[1]:match("[^/]+$")

						-- Load the plugin if it's lazy-loaded
						local lazy_ok, lazy_config = pcall(require, "lazy.core.config")
						if lazy_ok and lazy_config.plugins[plugin_name] then
							require("lazy.core.loader").load(lazy_config.plugins[plugin_name], { cmd = "colorscheme" })
						end

						-- Apply plugin-specific opts
						if entry.opts then
							local setup_name = plugin_name:gsub("%.nvim$", ""):gsub("%-", "_")
							pcall(function()
								require(setup_name).setup(entry.opts)
							end)
							-- Also try the original name
							pcall(function()
								require(plugin_name).setup(entry.opts)
							end)
						end

						-- Run plugin-specific config function
						if entry.config and type(entry.config) == "function" then
							pcall(entry.config)
						end
					end
				end

				if colorscheme then
					-- Clear highlights for clean theme application
					vim.cmd("highlight clear")
					if vim.fn.exists("syntax_on") then
						vim.cmd("syntax reset")
					end
					vim.o.background = "dark"

					-- Load and apply the colorscheme
					pcall(require, "lazy.core.loader")
					local loader_ok, loader = pcall(require, "lazy.core.loader")
					if loader_ok then
						pcall(loader.colorscheme, colorscheme)
					end

					pcall(vim.cmd.colorscheme, colorscheme)

					-- Reload transparency after theme change
					if vim.fn.filereadable(transparency_file) == 1 then
						vim.defer_fn(function()
							vim.cmd.source(transparency_file)
							vim.cmd("redraw!")
						end, 10)
					end
				end
			end

			-- Apply theme on startup
			apply_theme()

			-- Watch for theme changes from omarchy-theme-set
			local watch_dir = vim.fn.expand("~/.config/omarchy/current")
			local w = vim.uv.new_fs_event()
			if w then
				w:start(watch_dir, { recursive = false }, function(err, filename)
					if err then
						return
					end
					if filename == "theme.name" then
						-- Small delay to let omarchy-theme-set finish writing all files
						vim.defer_fn(function()
							apply_theme()
						end, 200)
					end
				end)
			end
		end,
	},
}
