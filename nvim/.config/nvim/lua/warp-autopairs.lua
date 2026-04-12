-- Warp-compatible autopairs using InsertCharPre
-- (Warp terminal doesn't trigger insert-mode mappings for printable characters)

local M = {}

local pairs = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	['"'] = '"',
	["'"] = "'",
	["`"] = "`",
}

-- Closing brackets that should jump over if already present
local closing_brackets = {
	[")"] = true,
	["]"] = true,
	["}"] = true,
}

-- Filetypes to skip for quote characters
local skip_quotes = {
	["'"] = { "rust", "nix" },
	['"'] = { "vim" },
}

local function should_skip(char)
	local ft = vim.bo.filetype
	local skip_list = skip_quotes[char]
	if skip_list then
		for _, skip_ft in ipairs(skip_list) do
			if ft == skip_ft then
				return true
			end
		end
	end
	return false
end

local function get_char_at_cursor()
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	return line:sub(col, col)
end

function M.setup()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		pattern = "*",
		callback = function()
			local char = vim.v.char

			-- Check if typing a closing bracket that we should jump over
			if closing_brackets[char] then
				local char_after = get_char_at_cursor()
				if char_after == char then
					vim.v.char = ""
					vim.schedule(function()
						local pos = vim.api.nvim_win_get_cursor(0)
						vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] + 1 })
					end)
					return
				end
			end

			local closing = pairs[char]

			if not closing then
				return
			end

			-- Skip quotes in certain filetypes
			if should_skip(char) then
				return
			end

			-- For quotes, don't pair if we're inside a word
			if char == closing then -- it's a quote character
				local col = vim.fn.col(".")
				local line = vim.fn.getline(".")
				local char_before = col > 1 and line:sub(col - 1, col - 1) or ""
				local char_after = line:sub(col, col)

				-- Skip if char after cursor is the same quote (jump over it)
				if char_after == char then
					vim.v.char = ""
					vim.schedule(function()
						local pos = vim.api.nvim_win_get_cursor(0)
						vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] + 1 })
					end)
					return
				end

				-- Skip if previous char is alphanumeric (likely in a word)
				if char_before:match("%w") then
					return
				end
			end

			-- Insert the pair
			vim.v.char = char .. closing
			vim.schedule(function()
				local pos = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
			end)
		end,
	})

	-- Handle backspace to delete pairs
	vim.keymap.set("i", "<BS>", function()
		local col = vim.fn.col(".")
		local line = vim.fn.getline(".")
		local char_before = col > 1 and line:sub(col - 1, col - 1) or ""
		local char_after = line:sub(col, col)

		if pairs[char_before] and pairs[char_before] == char_after then
			return "<BS><Del>"
		end
		return "<BS>"
	end, { expr = true, noremap = true })

	-- Handle Enter between pairs - add newline with indentation
	local bracket_pairs = {
		["("] = ")",
		["["] = "]",
		["{"] = "}",
	}

	vim.keymap.set("i", "<CR>", function()
		local col = vim.fn.col(".")
		local line = vim.fn.getline(".")
		local char_before = col > 1 and line:sub(col - 1, col - 1) or ""
		local char_after = line:sub(col, col)

		-- Expand bracket pairs
		if bracket_pairs[char_before] and bracket_pairs[char_before] == char_after then
			return "<CR><CR><Up><End><C-f>"
		end

		-- Expand HTML/JSX tags: >|</tag> -> expand with newlines
		if char_before == ">" and char_after == "<" then
			local after_cursor = line:sub(col)
			if after_cursor:match("^</") then
				return "<CR><CR><Up><End><C-f>"
			end
		end

		return "<CR>"
	end, { expr = true, noremap = true })
end

return M
