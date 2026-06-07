return {
	{
		"milanglacier/minuet-ai.nvim",
		config = function()
			require("minuet").setup({
				provider = "openai_fim_compatible",
				n_completions = 1,
				context_window = 512,
				virtualtext = {
					auto_trigger_ft = {},
					keymap = {
						-- accept whole completion
						accept = "<A-A>",
						-- accept one line
						accept_line = "<A-a>",
						-- accept n lines (prompts for number)
						-- e.g. "A-z 2 CR" will accept 2 lines
						accept_n_lines = "<A-z>",
						-- Cycle to prev completion item, or manually invoke completion
						prev = "<A-[>",
						-- Cycle to next completion item, or manually invoke completion
						next = "<A-]>",
						dismiss = "<A-e>",
					},
				},
				provider_options = {
					openai_fim_compatible = {
						-- For Windows users, TERM may not be present in environment variables.
						-- Consider using APPDATA instead.
						api_key = "KEY",
						name = "Llama.cpp",
						end_point = "http://localhost:8012/v1/completions",
						-- The model is set by the llama-cpp server and cannot be altered
						-- post-launch.
						model = "qwen2.5-coder-1.5b-q8_0.gguf",
						optional = {
							max_tokens = 56,
							top_p = 0.9,
						},
						-- Llama.cpp does not support the `suffix` option in FIM completion.
						-- Therefore, we must disable it and manually populate the special
						-- tokens required for FIM completion.
						template = {
							prompt = function(context_before_cursor, context_after_cursor, _)
								return "<|fim_prefix|>"
									.. context_before_cursor
									.. "<|fim_suffix|>"
									.. context_after_cursor
									.. "<|fim_middle|>"
							end,
							suffix = false,
						},
					},
				},
			})
		end,
	},
}
