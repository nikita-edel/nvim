return {
  "basola21/PDFview",
  enabled = false, -- TEMPORARY: testing texel.nvim (lua/plugins/texel.lua)
  lazy = false,
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()

	  vim.api.nvim_create_autocmd("BufReadPost", {
		  pattern = "*.pdf",
		  callback = function()
			  local file_path = vim.api.nvim_buf_get_name(0)
			  require("pdfview").open(file_path)
		  end,
	  })
  end,
}
