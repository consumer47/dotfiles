-- Weather in Neovim via wttr.in (no API key).
-- Use :Weather or <leader>tw to show weather; :Weather Berlin for another city.
return {
  "zachbuchli/weather.nvim",
  cmd = "Weather",
  keys = {
    { "<leader>tw", "<cmd>Weather<cr>", desc = "[W]eather" },
  },
  config = function()
    local weather = require("weather")
    weather.setup({
      -- Change to your city, or leave default (Portland). Examples: "Berlin", "London", "Tokyo"
      default_location = "Dortmund",
    })
  end,
}
