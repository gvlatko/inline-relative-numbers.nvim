local M = {
    marks = {},
}

M.setup = function(config)
    M.namespace = vim.api.nvim_create_namespace "inline-relative-numbers"

    vim.cmd [[command! -bang InlineRelativeNumbersRefresh lua require("inline-relative-numbers.commands").refresh("<bang>" == "!")]]
    vim.cmd [[highlight default link InlineRelativeNumbersLineNr Whitespace]]
    vim.cmd [[highlight default link InlineRelativeNumbersCursorLineNr CursorLineNr]]
    vim.cmd [[highlight clear ColorColumn]]

    vim.cmd [[
        augroup InlineRelativeNumbersAutogroup
            autocmd!
            autocmd ColorScheme * highlight clear ColorColumn
            autocmd ModeChanged,CursorMoved * InlineRelativeNumbersRefresh
            autocmd OptionSet colorcolumn InlineRelativeNumbersRefresh
            autocmd VimEnter,SessionLoadPost * InlineRelativeNumbersRefresh!
        augroup END
    ]]
end

M.count_whitespace = function(s)
    local white = 0
    if s then
        for ch in string.gmatch(s, ".") do
            if ch == " " then
                white = white + 1
            else
                break
            end
        end
    end

    return white
end

M.refresh = function()
    local bufnr = vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end

    local mode = vim.api.nvim_get_mode()["mode"]

    local bufType = vim.api.nvim_get_option_value("buftype", {
        buf = bufnr,
    })

    if bufType == "terminal" or bufType == "prompt" then
        return
    end

    if mode == "i" then
        for _, m in pairs(M.marks) do
            vim.api.nvim_buf_del_extmark(bufnr, M.namespace, m)
        end
        return
    end

    local visibleLinesStart = vim.fn.line "w0"
    local visibleLinesEnd = vim.fn.line "w$"

    local lineStart = 0
    local linesEnd = vim.fn.line "$"

    local cursorLine = vim.fn.line "."

    for currentLine = cursorLine, visibleLinesStart, -1 do
        M.drawLineNumber(bufnr, cursorLine, currentLine)
    end

    for currentLine = cursorLine, visibleLinesEnd, 1 do
        M.drawLineNumber(bufnr, cursorLine, currentLine)
    end
end

M.drawLineNumber = function(bufnr, cursorLine, currentLine)
    local line = vim.api.nvim_buf_get_lines(bufnr, currentLine - 1, currentLine, false)

    local lineWhitespace = M.count_whitespace(line[1])

    local text = cursorLine
    local textColor = "InlineRelativeNumbersCursorLineNr"

    if currentLine ~= cursorLine then
        text = math.abs(currentLine - cursorLine)
        textColor = "InlineRelativeNumbersLineNr"
    end

    if lineWhitespace > 2 then
        local offset = lineWhitespace - #tostring(i)
        if offset < 0 then
            offet = 0
        end

        if M.marks[currentLine - 1] then
            vim.api.nvim_buf_set_extmark(bufnr, M.namespace, currentLine - 1, offset, {
                id = M.marks[currentLine - 1],
                virt_text = { { tostring(text), textColor } },
                virt_text_pos = "overlay",
                hl_mode = "combine",
                priority = 1,
            })
        else
            local markdId = vim.api.nvim_buf_set_extmark(bufnr, M.namespace, currentLine - 1, offset, {
                virt_text = { { tostring(text), textColor } },
                virt_text_pos = "overlay",
                hl_mode = "combine",
                priority = 1,
            })

            M.marks[currentLine - 1] = markdId
        end
    end
end

return M
