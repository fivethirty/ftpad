const STORAGE_KEY = "ftpad-content";

const pad = document.getElementById("pad") as HTMLTextAreaElement;
pad.value = localStorage.getItem(STORAGE_KEY) ?? "";
pad.addEventListener("input", () => localStorage.setItem(STORAGE_KEY, pad.value));
pad.focus();
