-- HuggingFace llm.nvim: ghost-text code completion (Copilot-style).
-- Backend: Ollama (local). Install Ollama and run e.g. ollama pull codellama:7b.
-- To use HuggingFace Inference API instead: set backend = "huggingface", model = "bigcode/starcoder2-15b",
-- and set LLM_NVIM_HF_API_TOKEN or HF_HOME/token. Then :LLMToggleAutoSuggest to enable.
return {
  {
    "huggingface/llm.nvim",
    name = "llm_ghost", -- avoid conflict with Chunt0/llm.nvim (both use dir "llm.nvim")
    opts = {
      backend = "ollama",
      model = "codellama:7b",
      url = "http://localhost:11434",
      request_body = {
        options = {
          temperature = 0.2,
          top_p = 0.95,
        },
      },
      fim = {
        enabled = true,
        prefix = " ",
        middle = " ",
        suffix = " ",
      },
      context_window = 1024,
      -- Off by default so no connection to Ollama until you run :LLMToggleAutoSuggest (or <leader>at).
      enable_suggestions_on_startup = false,
      enable_suggestions_on_files = "*",
      -- Don't use Tab so insert-mode Tab works for indent/completion. Accept/dismiss ghost text with Ctrl+Y / Ctrl+E.
      accept_keymap = "<C-y>",
      dismiss_keymap = "<C-e>",
    },
    config = function(plugin, opts)
      -- Load HuggingFace's llm from this plugin's dir (Chunt0 also has "llm" and is cached first).
      local saved_llm = package.loaded["llm"]
      package.loaded["llm"] = nil
      local prepend = (plugin.dir or "") .. "/lua/?.lua;" .. (plugin.dir or "") .. "/lua/?/init.lua;"
      local orig_path = package.path
      package.path = prepend .. package.path
      local ok, hf_llm = pcall(require, "llm")
      package.path = orig_path
      package.loaded["llm"] = saved_llm
      if ok and hf_llm and hf_llm.setup then
        hf_llm.setup(opts)
      end
      vim.keymap.set("n", "<leader>at", "<cmd>LLMToggleAutoSuggest<cr>", { desc = "LLM ghost-text toggle" })
    end,
  },
}
