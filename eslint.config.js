import globals from "globals";

export default [
	{
		// The Tampermonkey userscript runs in the browser as a classic script (IIFE).
		files: ["plex-outplayer.js"],
		languageOptions: {
			ecmaVersion: 2022,
			sourceType: "script",
			globals: {
				...globals.browser,
			},
		},
		rules: {
			"no-undef": "error",
			// Pre-existing style leaves a few intentionally-unused params (e.g. filename);
			// surface real dead variables as warnings without failing CI.
			"no-unused-vars": ["warn", { args: "none" }],
			"no-empty": ["warn", { allowEmptyCatch: true }],
		},
	},
	{
		// Node tooling (tests, scripts) is written as ES modules.
		files: ["scripts/**/*.mjs", "test/**/*.mjs", "eslint.config.js"],
		languageOptions: {
			ecmaVersion: 2022,
			sourceType: "module",
			globals: {
				...globals.node,
			},
		},
		rules: {
			"no-undef": "error",
			"no-unused-vars": "warn",
		},
	},
];
