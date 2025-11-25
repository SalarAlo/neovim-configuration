vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "<C-d>", "<C-d>zz")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<C-Up>",    ":resize +2<CR>",          { desc = "Increase height" })
keymap.set("n", "<C-Down>",  ":resize -2<CR>",          { desc = "Decrease height" })
keymap.set("n", "<C-Left>",  ":vertical resize -4<CR>", { desc = "Narrower" })
keymap.set("n", "<C-Right>", ":vertical resize +4<CR>", { desc = "Wider" })

-- tab management
keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Go to next buffer" })
keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Go to previous buffer" })
keymap.set("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close current buffer" })
keymap.set("n", "<leader>n", "<cmd>tabnew<CR>", { desc = "New tab" })

-- file explorer
keymap.set("n", "<C-n>", "<cmd>Ex<CR>", { desc = "Open file explorer" })

vim.keymap.set("n", "<leader>ci", "<cmd>Telescope lsp_incoming_calls<CR>") 
vim.keymap.set("n", "<leader>co", "<cmd>Telescope lsp_outgoing_calls<CR>")
vim.keymap.set("n", "<leader>ch", "<cmd>Telescope lsp_implementations<CR>")
vim.keymap.set("n", "<leader>cu", "<cmd>Telescope lsp_references<CR>")
