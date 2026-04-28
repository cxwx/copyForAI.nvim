-- GEMINI:
local M = {}

local function copy_for_ai()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 1. 获取选区行号 (使用内置标记 '< 和 '>)
  -- '< 是选区起点，'> 是选区终点
  local start_line = vim.fn.getpos("'<")[2] - 1
  local end_line = vim.fn.getpos("'>")[2]

  -- 容错处理：如果没在可视化模式选过，则获取当前行
  if start_line < 0 then
    start_line = vim.fn.line(".") - 1
    end_line = vim.fn.line(".")
  end

  -- 2. 获取代码内容
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local code = table.concat(lines, "\n")

  -- 3. 获取 LSP 诊断信息
  local diags = vim.diagnostic.get(bufnr)
  local diag_list = {}
  for _, d in ipairs(diags) do
    if d.lnum >= start_line and d.lnum < end_line then
      local severity = vim.diagnostic.severity[d.severity] or "INFO"
      table.insert(diag_list, string.format("[%s] 行 %d: %s", severity, d.lnum + 1, d.message))
    end
  end
  local diag_str = #diag_list > 0 and table.concat(diag_list, "\n") or "未发现 LSP 问题。"

  -- 4. 构造最终 Markdown 文本
  local file_path = vim.fn.expand("%:p")
  local ft = vim.bo.filetype
  local parts = {
    "### 开发者上下文 (来自 Neovim)",
    "**文件路径:** `" .. file_path .. "`",
    "**语言:** " .. ft,
    "",
    "#### 源代码片段:",
    "```" .. ft,
    code,
    "```",
    "",
    "#### LSP 诊断与报错:",
    "```text",
    diag_str,
    "```",
    "",
    "---",
    "请根据以上代码和报错信息给出修复建议。",
  }
  local final_text = table.concat(parts, "\n")

  -- 5. 写入剪贴板
  vim.fn.setreg("+", final_text)

  -- 反馈通知
  vim.notify("✅ 已捕获 " .. (end_line - start_line) .. " 行及 " .. #diag_list .. " 条报错", 
    vim.log.levels.INFO, 
    { title = "AI Exporter" })
  
  -- 强制退出 Visual 模式
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
end

function M.setup()
  -- 【关键修复】：添加 { range = true } 允许命令处理选区
  vim.api.nvim_create_user_command("CopyForAI", function()
    copy_for_ai()
  end, { range = true })
  
  -- 建议：绑定一个快捷键方便在 Visual 模式下直接呼叫
  -- vim.keymap.set("v", "<leader>ca", ":CopyForAI<CR>", { desc = "Copy selection for AI" })
end

return M
