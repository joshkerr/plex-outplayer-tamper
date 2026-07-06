// Fails if plex-outplayer.js changed versus the base ref without bumping its
// @version header. Run in CI on pull requests. Locally: BASE_REF=origin/main npm run check:version
import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";

const FILE = "plex-outplayer.js";
const base = process.env.BASE_REF || "origin/main";

function versionOf(text) {
	const match = text.match(/@version\s+(\S+)/);
	return match ? match[1] : null;
}

const headVersion = versionOf(readFileSync(FILE, "utf8"));
if (!headVersion) {
	console.error(`ERROR: no @version header found in ${FILE}`);
	process.exit(1);
}

let baseText;
try {
	baseText = execSync(`git show ${base}:${FILE}`, { encoding: "utf8" });
} catch {
	console.log(`Base ${base}:${FILE} not available (new file?) - skipping bump check.`);
	process.exit(0);
}

let changed = true;
try {
	execSync(`git diff --quiet ${base} -- ${FILE}`, { stdio: "ignore" });
	changed = false;
} catch {
	changed = true;
}

if (!changed) {
	console.log(`${FILE} unchanged vs ${base} - OK.`);
	process.exit(0);
}

const baseVersion = versionOf(baseText);
if (baseVersion === headVersion) {
	console.error(
		`ERROR: ${FILE} changed but @version is still ${headVersion}. ` +
			`Bump the @version header in the userscript metadata block.`,
	);
	process.exit(1);
}

console.log(`OK: @version bumped ${baseVersion} -> ${headVersion}.`);
