return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 900,
	opts = {
		indent = {
			enabled = true,
			animate = {
				enabled = true,
			},
		},
		-- Disable modules that overlap with existing plugins
		dashboard = { enabled = false },
		scroll = { enabled = false },
		notifier = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
	},
}
