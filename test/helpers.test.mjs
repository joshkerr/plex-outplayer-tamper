// Unit tests for the pure, DOM-independent helpers in plex-outplayer.js.
//
// The userscript ships as a single self-contained file (no build step), so rather
// than duplicate the helper implementations here, we extract the real source blocks
// straight out of plex-outplayer.js (sliced between their anchor comments) and run
// them in a sandbox. If someone renames those anchor comments this test fails loudly,
// which is fine - it lives right next to the code it guards.
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import vm from "node:vm";

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(join(here, "..", "plex-outplayer.js"), "utf8");

function sliceBetween(startMarker, endMarker) {
	const start = source.indexOf(startMarker);
	const end = source.indexOf(endMarker, start + startMarker.length);
	assert.notEqual(start, -1, `anchor not found: ${startMarker}`);
	assert.notEqual(end, -1, `anchor not found: ${endMarker}`);
	return source.slice(start, end);
}

// Grab each self-contained helper block (its module-level consts + the function).
const blocks = [
	sliceBetween(
		"// Redact potentially sensitive information from a URL",
		"// Turn a number of bytes to a more friendly size display",
	),
	sliceBetween(
		"// Turn a number of bytes to a more friendly size display",
		"// Turn a number of milliseconds to a more friendly HH:MM:SS display",
	),
	sliceBetween(
		"// Turn a number of milliseconds to a more friendly HH:MM:SS display",
		"// The modal is the popup",
	),
	sliceBetween(
		"// Parse current URL to get clientId and metadataId",
		"// Start fetching a media item from the URL parameters",
	),
];

// Evaluate the extracted blocks in a sandbox that mimics the browser globals they use.
const sandbox = { URL, location: { hash: "" }, console };
vm.createContext(sandbox);
vm.runInContext(
	blocks.join("\n") +
		"\nglobalThis.__helpers = { redactUrl, makeFilesize, makeDuration, parseUrl };",
	sandbox,
);
const { redactUrl, makeFilesize, makeDuration, parseUrl } = sandbox.__helpers;

test("redactUrl scrubs IP, server hash and token", () => {
	const out = redactUrl(
		"https://192-168-1-5.abcdef0123456789ff.plex.direct:32400/library/metadata/1?X-Plex-Token=supersecret",
	);
	assert.match(out, /1-1-1-1/, "IP-style label replaced");
	// The URL setter re-normalises the hostname to lowercase, so the redaction reads as x's.
	assert.match(out, /x{16}/i, "hex server id replaced");
	assert.match(out, /X-Plex-Token=REDACTED/, "token redacted");
	assert.doesNotMatch(out, /supersecret/, "raw token must not survive");
	assert.doesNotMatch(out, /192-168-1-5/, "raw IP must not survive");
	assert.doesNotMatch(out, /abcdef0123456789/, "raw server id must not survive");
});

test("redactUrl returns ? for malformed input", () => {
	assert.equal(redactUrl("not a url"), "?");
});

test("makeFilesize formats byte counts", () => {
	assert.equal(makeFilesize(0), "0 B");
	assert.equal(makeFilesize(1023), "1023 B");
	assert.equal(makeFilesize(1024), "1.00 KB");
	assert.equal(makeFilesize(1536), "1.50 KB");
	assert.equal(makeFilesize(1048576), "1.00 MB");
});

test("makeFilesize returns ? for invalid input", () => {
	assert.equal(makeFilesize(-5), "?");
	assert.equal(makeFilesize("abc"), "?");
});

test("makeDuration formats milliseconds", () => {
	assert.equal(makeDuration(7000), "0:07");
	assert.equal(makeDuration(125000), "2:05");
	assert.equal(makeDuration(7384000), "2:03:04");
});

test("makeDuration returns ? for invalid input", () => {
	assert.equal(makeDuration(-1), "?");
	assert.equal(makeDuration("nope"), "?");
});

test("parseUrl extracts clientId and metadataId from a details hash", () => {
	sandbox.location.hash =
		"#!/server/fd174cfae71eba992435d781704afe857609471b/details?key=%2Flibrary%2Fmetadata%2F25439&context=home";
	assert.deepEqual({ ...parseUrl() }, {
		clientId: "fd174cfae71eba992435d781704afe857609471b",
		metadataId: "25439",
	});
});

test("parseUrl handles collections", () => {
	sandbox.location.hash =
		"#!/server/fd174cfae71eba992435d781704afe857609471b/details?key=%2Flibrary%2Fcollections%2F1234";
	assert.deepEqual({ ...parseUrl() }, {
		clientId: "fd174cfae71eba992435d781704afe857609471b",
		metadataId: "1234",
	});
});

test("parseUrl returns false for non-matching hashes", () => {
	sandbox.location.hash = "#!/home";
	assert.equal(parseUrl(), false);
	sandbox.location.hash = "/not-a-shebang";
	assert.equal(parseUrl(), false);
});
