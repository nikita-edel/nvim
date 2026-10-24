local map = vim.keymap.set

-- pdf view
vim.api.nvim_create_autocmd("FileType", {
	pattern = "pdfview",
	callback = function(ev)
		local renderer = require("pdfview.renderer")
		map("n", "J", renderer.next_page, { buffer = ev.buf, desc = "PDFview: Next page", noremap = true, silent = true })
		map("n", "K", renderer.previous_page, { buffer = ev.buf, desc = "PDFview: Previous page", noremap = true, silent = true })
	end,
})
