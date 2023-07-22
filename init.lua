local old_stdpath = vim.fn.stdpath
OUTPUT_BASE = os.getenv("OUTPUTBASE");
vim.fn.stdpath = function(value)
    if value == "data" then
        return os.getenv("XDG_DATA_HOME") .. "/hurlord"
    end
    if value == "cache" then
        return os.getenv("XDG_CACHE_HOME") .. "/hurlord"
    end
    if value == "config" then
        return os.getenv("HURLORD_HOME")
    end
    return old_stdpath(value)
end
vim.opt.runtimepath:remove(vim.fn.expand('~/.config/nvim'))
vim.opt.packpath:remove(vim.fn.expand('~/.local/share/nvim/site'))
vim.opt.runtimepath:append(vim.fn.stdpath('config'))
vim.opt.packpath:append(vim.fn.stdpath('data') .. '/packages')

vim.g.mapleader = ' '
vim.opt.fillchars = { eob = " " }
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.shortmess:append({ I = true })
vim.o.noshowcmd = 1
vim.o.laststatus = 1
vim.opt.showmode = false
vim.opt.swapfile = false
vim.o.clipboard = "unnamedplus"
vim.keymap.set("n", "r", ":qa!<CR>");
vim.opt.cmdheight = 0

--config = vim.tbl_deep_extend('force', config, opts)
vim.opt.termguicolors = true
--vim.cmd("140 vsplit");
--

pickerWinId = vim.api.nvim_get_current_win();
vim.cmd.terminal({ "nnn" });
vim.cmd.file("picker");
vim.opt.statusline = "%= %f %="

function getWindowBufName(window)
    return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(window))
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
    callback = function()
        vim.cmd.startinsert();
        vim.api.nvim_set_current_win(pickerWinId)
    end
})
WINDOWS_INITIALIZED = false

function initWindows()
    if not WINDOWS_INITIALIZED then
        vim.o.splitright = true;
        vim.cmd("vsplit")
        editorWinId = vim.api.nvim_get_current_win();
        vim.cmd("vsplit")
        OUTPUT_WIN_ID = vim.api.nvim_get_current_win();
        local tempOutputBufId = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(OUTPUT_WIN_ID, tempOutputBufId);
        vim.api.nvim_buf_set_name(tempOutputBufId, "output");
        WINDOWS_INITIALIZED = true
        resizeAll()
    end
end

vim.api.nvim_create_autocmd({ "VimResized" }, {
    callback = function()
    end
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
    callback = function()
        vim.cmd.startinsert();
    end
})
isSmaller = false
resizeAll = function()
    local wholeTerminalWidth = vim.go.columns

    if wholeTerminalWidth < 80 then
        if isSmaller == false then
            toSmallerLayout();
            isSmaller = true;
        end
        vim.api.nvim_win_set_width(pickerWinId, math.floor(wholeTerminalWidth * 0.22))
        vim.api.nvim_win_set_width(editorWinId, math.floor(wholeTerminalWidth * 0.78))
    elseif wholeTerminalWidth >= 80 then
        if isSmaller == true then
            fromSmallerLayout()
            isSmaller = false
        end
        vim.api.nvim_win_set_width(pickerWinId, math.floor(wholeTerminalWidth * 0.12))
        vim.api.nvim_win_set_width(OUTPUT_WIN_ID, math.floor(wholeTerminalWidth * 0.40))
    end

    -- Leaving the biggest portion for the editor
end
--vim.cmd("30 split")
--vim.api.nvim_set_current_win(primaryEditingSpaceWinId);
--requestPickerWinId=vim.api.nvim_get_current_win();
function getFileNameWithoutExtension(path)
    -- Find the position of the last slash or backslash in the path
    local lastSlashPos = path:find("[/\\][^/\\]*$")

    -- If a slash or backslash is found, extract the file name
    local fileName = lastSlashPos and path:sub(lastSlashPos + 1) or path

    -- Find the position of the last dot in the file name (before the extension)
    local lastDotPos = fileName:find("%.[^%.]*$")

    -- If a dot is found, remove the extension from the file name
    return lastDotPos and fileName:sub(1, lastDotPos - 1) or fileName
end

runHurl = function()
    vim.cmd("silent write")
    toBeRunBufNumber = vim.api.nvim_win_get_buf(editorWinId)
    toBeRunPath = vim.api.nvim_buf_get_name(toBeRunBufNumber)

    outputPath = vim.fn.system("executer " .. toBeRunPath);
    if outputPath ~= "" then
        vim.cmd.badd(outputPath)
        local outputBufferId = vim.api.nvim_list_bufs()[#vim.api.nvim_list_bufs()]
        vim.api.nvim_win_set_buf(OUTPUT_WIN_ID, outputBufferId);
    else
        print("Request file can't be empty")
    end
end


prepareEditor = function()
    initWindows()
    vim.api.nvim_set_current_win(editorWinId)
end

prepareOutput = function()
    initWindows()
    vim.api.nvim_set_current_win(OUTPUT_WIN_ID)
end
focusOnEditor = function()
    vim.api.nvim_set_current_win(editorWinId)
end

focusOnPicker = function()
    vim.cmd.startinsert();
    vim.api.nvim_set_current_win(pickerWinId)
end

focusOnOutput = function()
    vim.api.nvim_set_current_win(OUTPUT_WIN_ID)
end

toSmallerLayout = function()
    focusOnPicker()
    vim.api.nvim_win_close(OUTPUT_WIN_ID, true)
    focusOnEditor()
    vim.cmd("belowright split output")
    OUTPUT_WIN_ID = vim.api.nvim_get_current_win();
    focusOnEditor()
end

fromSmallerLayout = function()
    focusOnOutput()
    vim.api.nvim_win_close(OUTPUT_WIN_ID, true)
    focusOnEditor()
    vim.cmd("vsplit output")
    OUTPUT_WIN_ID = vim.api.nvim_get_current_win();
    focusOnEditor()
end

vim.keymap.set("n", "<enter>", runHurl);
vim.keymap.set("n", "<F1>", focusOnPicker);
vim.keymap.set({ "t", "n" }, "<F2>", focusOnEditor);
vim.keymap.set({ "t", "n" }, "<F3>", focusOnOutput);


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath, }) end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")
P = function(a)
    print(vim.inspect(a))
end

vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#005577", fg = "#ffffff", sp = nil })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "#B400B4", fg = nil, sp = nil })
vim.api.nvim_set_hl(0, "WinSeparator", { bg = nil, fg = "#005577", sp = nil })
