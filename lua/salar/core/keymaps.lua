vim.g.mapleader = " "

local keymap = vim.keymap

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- tab management
keymap.set("n", "<Tab>", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<S-Tab>", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>x", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>n", "<cmd>tabnew<CR>", { desc = "New tab" })

-- file explorer
keymap.set("n", "<C-n>", "<cmd>Ex<CR>", { desc = "Open file explorer" })
