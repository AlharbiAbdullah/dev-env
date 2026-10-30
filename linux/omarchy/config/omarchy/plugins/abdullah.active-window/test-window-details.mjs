import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const formatter = vm.createContext({});
vm.runInContext(readFileSync(new URL("./window-details.js", import.meta.url), "utf8"), formatter);

test("terminal sessions put the folder before task details", () => {
  assert.equal(formatter.format("com.mitchellh.ghostty", "Explain Linux status bar | helm").text,
    "Ghostty - helm - Explain Linux status bar");
  assert.equal(formatter.format("com.mitchellh.ghostty", "task | ~/projects/my-folder/").text,
    "Ghostty - my-folder - task");
});

test("terminal prompts report the current directory without repeating the prompt", () => {
  assert.equal(formatter.format("com.mitchellh.ghostty",
    "abdullah@omarchy:~/playground/fastapi-learning").text, "Ghostty - fastapi-learning");
  assert.equal(formatter.format("com.mitchellh.ghostty", "~/").text, "Ghostty - home");
  assert.equal(formatter.format("com.mitchellh.ghostty", "/").text, "Ghostty - /");
});

test("editors show project or vault before file details", () => {
  assert.equal(formatter.format("com.microsoft.VSCode", "main.py - fastapi-learning - Visual Studio Code").text,
    "VS Code - fastapi-learning - main.py");
  assert.equal(formatter.format("md.obsidian.Obsidian", "New tab - helm - Obsidian 1.14.4").text,
    "Obsidian - helm - New tab");
  assert.equal(formatter.format("com.microsoft.VSCode", "Welcome - Visual Studio Code").folder, "");
});

test("browser page punctuation does not become an invented folder", () => {
  const result = formatter.format("google-chrome", "FastAPI - YouTube - Google Chrome");
  assert.equal(result.text, "Chrome - FastAPI - YouTube");
  assert.equal(result.folder, "");
  assert.equal(formatter.format("chrome-github.com__AlharbiAbdullah-Default", "GitHub").text,
    "Chrome - GitHub");
});

test("missing folders and unknown programs preserve available details", () => {
  assert.equal(formatter.format("com.mitchellh.ghostty", "Lesson 12").text, "Ghostty - Lesson 12");
  assert.equal(formatter.format("com.microsoft.VSCode", "").text, "VS Code");
  assert.equal(formatter.format("com.github.PintaProject.Pinta", "Unsaved Image 1* - Pinta").program,
    "Pinta");
});
