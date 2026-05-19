-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return vim.tbl_flatten({
  require("custom.plugins.llm"),
  require("custom.plugins.llm_ghost"),
  require("custom.plugins.weather"),
})
