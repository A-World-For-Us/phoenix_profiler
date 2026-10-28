const SHOW = "phxprof-toolbar-show";

const toolbar = document.querySelector(".phxprof-toolbar");

function toggleToolbar(open) {
  toolbar.classList.toggle("miniaturized", !open);
  localStorage.setItem(SHOW, String(open));
}

toolbar
  .querySelector(".show-button")
  .addEventListener("click", () => toggleToolbar(true));
toolbar
  .querySelector(".hide-button")
  .addEventListener("click", () => toggleToolbar(false));

toggleToolbar(localStorage.getItem(SHOW) === "true");

window.getPhxProfToken = () => toolbar.dataset.token;

// ─── Queries dialog ─────────────────────────────────────────────────
//
// The dialog lives inside the toolbar LiveView. Every time new entries arrive
// the LiveView re-renders and the DOM patch strips the `open` attribute that
// `showModal()` added (the server never renders it). In Chrome the dialog then
// stays in the top layer while hidden, which leaves the page inert: the user
// can neither see the dialog nor click to reopen it. We track the wanted state
// ourselves and restore the modal right after each patch.

const stacktraceDialog = document.getElementById("phxprof--stacktrace");
let stacktraceDialogWanted = false;

function showStackDialog() {
  if (stacktraceDialog.open) return;
  const active = document.activeElement;
  stacktraceDialog.showModal();
  // showModal() moves focus to the first focusable element; keep the user's focus.
  if (active && active !== document.body && stacktraceDialog.contains(active)) {
    active.focus();
  }
}

function openStackDialog() {
  stacktraceDialogWanted = true;
  showStackDialog();
}

function closeStackDialog() {
  stacktraceDialogWanted = false;
  stacktraceDialog.close();
}

new MutationObserver(() => {
  if (stacktraceDialogWanted && !stacktraceDialog.open) showStackDialog();
}).observe(stacktraceDialog, { attributes: true, attributeFilter: ["open"] });

document.getElementById("show-dialog").addEventListener("click", (e) => {
  e.preventDefault();
  openStackDialog();
});
document
  .getElementById("close-dialog")
  .addEventListener("click", () => closeStackDialog());
stacktraceDialog.addEventListener("click", (e) => {
  if (e.target === stacktraceDialog) closeStackDialog();
});
// Escape key: the browser closes the dialog itself, keep our state in sync.
stacktraceDialog.addEventListener("cancel", () => {
  stacktraceDialogWanted = false;
});

// ─── Query table sorting ────────────────────────────────────────────

let querySort = { col: "count", dir: "desc" };

function applyQuerySort() {
  const list = document.getElementById("query_list");
  if (!list) return;

  const rows = Array.from(list.querySelectorAll(".phxprof-query-row"));
  if (rows.length === 0) return;

  const cellClass = {
    count: ".phxprof-query-count",
    time: ".phxprof-query-time",
    data: ".phxprof-query-data",
  }[querySort.col];

  const sorted = rows.slice().sort((a, b) => {
    const av = parseFloat(a.querySelector(cellClass)?.dataset.sortValue ?? 0);
    const bv = parseFloat(b.querySelector(cellClass)?.dataset.sortValue ?? 0);
    return querySort.dir === "asc" ? av - bv : bv - av;
  });

  // Moving nodes blurs the focused element; only do it when the order changed.
  if (sorted.some((r, i) => r !== rows[i])) {
    sorted.forEach((r) => list.appendChild(r));
  }
  updateSortHeaders();
}

function sortQueryList(col) {
  if (querySort.col === col) {
    querySort.dir = querySort.dir === "asc" ? "desc" : "asc";
  } else {
    querySort.col = col;
    querySort.dir = "desc";
  }

  applyQuerySort();
}

function updateSortHeaders() {
  document.querySelectorAll(".phxprof-sort-btn").forEach((btn) => {
    const icon = btn.querySelector(".phxprof-sort-icon");
    if (!icon) return;
    icon.textContent = btn.dataset.sortCol === querySort.col
      ? (querySort.dir === "asc" ? "▲" : "▼")
      : "";
  });
}

document.addEventListener("click", (e) => {
  const btn = e.target.closest(".phxprof-sort-btn");
  if (btn) sortQueryList(btn.dataset.sortCol);
});

// A LiveView patch rewrites the rows in server order (execution count, desc)
// and resets the header icons; re-apply the sort the user chose.
const queryListObserver = new MutationObserver(() => {
  applyQuerySort();
  // Drop the records produced by our own changes to avoid re-triggering.
  queryListObserver.takeRecords();
});
queryListObserver.observe(stacktraceDialog, {
  childList: true,
  subtree: true,
  characterData: true,
  attributeFilter: ["data-sort-value"],
});
