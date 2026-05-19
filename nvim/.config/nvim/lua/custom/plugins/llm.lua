-- Chunt0/llm.nvim: streaming LLM (OpenAI, etc.) into the buffer.
-- API key: set OPENAI_API_KEY in env, or it is read from ~/.openai_api_key on load.
--
-- Keymaps (which-key shows these under <space>a):
--   ao  invoke (prompt in n, selection in v)
--   ar  replace selection with model output (visual)
--   ah  chat with buffer context (visual)
--   ac  clear conversation memory
return {
  {
    "Chunt0/llm.nvim",
    name = "llm_chunt0", -- separate dir so HuggingFace llm.nvim does not overwrite
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Use ~/.openai_api_key if OPENAI_API_KEY is not already set (e.g. from shell)
      if not vim.env.OPENAI_API_KEY or vim.env.OPENAI_API_KEY == "" then
        local keyfile = vim.fn.expand("~/.openai_api_key")
        if vim.fn.filereadable(keyfile) == 1 then
          local lines = vim.fn.readfile(keyfile)
          if #lines > 0 and lines[1] ~= "" then
            vim.env.OPENAI_API_KEY = lines[1]
          end
        end
      end

      require("llm_config").setup({
        ui = { mode = "float", throttle_ms = 20 },
        memory = { enabled = true, max_messages = 20 },
        context = { max_buffer_bytes = 200 * 1024 },
        logging = { enabled = false, redact = true },
        network = { max_time = 120, retry = 2 },
      })

      local openai = require("openai")

      -- Invoke with prompt (no selection): ask for input, insert it, select it, then invoke.
      local function invoke_with_prompt()
        local prompt = vim.fn.input("Prompt: ")
        if prompt == "" then
          return
        end
        vim.api.nvim_put({ prompt }, "l", true, true)
        vim.cmd("normal! V")
        openai.invoke()
      end

      vim.keymap.set("n", "<leader>ao", invoke_with_prompt, { desc = "LLM invoke (prompt)" })
      vim.keymap.set("v", "<leader>ao", openai.invoke, { desc = "LLM invoke (selection)" })
      vim.keymap.set("v", "<leader>ar", openai.code, { desc = "LLM replace selection" })
      vim.keymap.set("v", "<leader>ah", openai.code_chat, { desc = "LLM chat (buffer context)" })
      vim.keymap.set("n", "<leader>ac", "<cmd>LLMClear<cr>", { desc = "LLM clear memory" })
    end,
  },
}
