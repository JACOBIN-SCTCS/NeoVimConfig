return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      local rules_file = '/Users/depressedcoder/.config/nvim/pmd/formatter.xml'

      -- print('Linter working directory' .. working_directory_src)
      lint.linters.pmd_java = {
        cmd = '/Users/depressedcoder/.config/nvim/pmd/bin/pmd',
        stdin = false,
        name = 'PMD Linter',
        append_fname = true,
        args = {
          'check',
          '-R',
          rules_file,
          '-f',
          'text',
        },
        stream = nil,
        ignore_exitcode = true,
        env = nil,
        parser = function(output, buffernum, linter_cwd)
          local diagnostics = {}
          for line in vim.gsplit(output, '\n', { trimempty = true }) do
            local sep = ':'
            -- print('Buffer Number of error' .. buffernum)
            message_contents = {}
            for str in string.gmatch(line, '([^' .. sep .. ']+)') do
              table.insert(message_contents, str)
            end
            table.insert(diagnostics, {
              bufnr = tonumber(buffernum),
              lnum = tonumber(message_contents[2]) - 1,
              col = 0,
              end_col = 80,
              severity = vim.diagnostic.severity.WARN,
              source = 'pmd java',
              message = message_contents[4],
            })
          end
          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        --java = { 'pmd_java' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
