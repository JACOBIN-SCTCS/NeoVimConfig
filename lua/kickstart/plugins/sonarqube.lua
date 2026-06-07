return {
    {
        "iamkarasik/sonarqube.nvim",
        config = function ()
            local extension_path = vim.fn.stdpath("data") .. "/mason/packages/sonarlint-language-server/extension"

            require("sonarqube").setup({
                lsp = {
                    cmd = {
                        vim.fn.exepath("java"),
                        "-jar",
                        extension_path .. "/server/sonarlint-ls.jar",
                        "-stdio",
                        "-analyzers",
                        extension_path .. "/analyzers/sonargo.jar",
                        extension_path .. "/analyzers/sonarhtml.jar",
                        extension_path .. "/analyzers/sonariac.jar",
                        extension_path .. "/analyzers/sonarjava.jar",
                        extension_path .. "/analyzers/sonarjavasymbolicexecution.jar",
                        extension_path .. "/analyzers/sonarjs.jar",
                        extension_path .. "/analyzers/sonarphp.jar",
                        extension_path .. "/analyzers/sonarpython.jar",
                        extension_path .. "/analyzers/sonartext.jar",
                        extension_path .. "/analyzers/sonarxml.jar",
                    },
                    log_level = "OFF",
                    handlers = {
                        -- Custom handler to show rule description
                        -- The `res` argument contains various keys containing html that can be rendered in your favourite neovim html plugin 
                        -- Alternatively, open the rule in the browser using your favourite sonarqube rule website (example below)
                        ["sonarlint/showRuleDescription"] = function(err, res, ctx, cfg)
                            local uri = "https://rules.sonarsource.com/%s/RSPEC-%s"
                            local lang = res.languageKey
                            local spec = string.match(res.key, "S(%d+)")
                            vim.ui.open(string.format(uri, lang, spec))
                        end,
                    },
                },
                rules = {
                    enabled=true
                },
                python = {
                    enabled=true
                }

            })
        end
    }
}
