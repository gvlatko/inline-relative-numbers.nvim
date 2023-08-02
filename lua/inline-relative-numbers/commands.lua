local M = {}

M.refresh = function(bang)
    if bang then
        local win = vim.api.nvim_get_current_win()
        vim.cmd [[noautocmd windo lua require("inline-relative-numbers").refresh()]]
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
            vim.cmd [[lua require("inline-relative-numbers").refresh()]]
        end
    else
        vim.cmd [[lua require("inline-relative-numbers").refresh()]]
    end
end

return M
