return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = {
				"bash",
				"c",
				"css",
				"cpp",
				"diff",
				"go",
				"html",
				"javascript",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"rust",
				"scss",
				"svelte",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
			},
		})
	end,
}

