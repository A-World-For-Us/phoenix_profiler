const SHOW = "phxprof-toolbar-show";

const toolbar = document.querySelector(".phxprof-toolbar");

function toggleToolbar(open) {
  toolbar.classList.toggle("miniaturized", !open);
  localStorage.setItem(SHOW, String(open));
}

function toggleStackDialog(){
	document.getElementById("phxprof--stacktrace").showModal();
}

toolbar
  .querySelector(".show-button")
  .addEventListener("click", () => toggleToolbar(true));
toolbar
  .querySelector(".hide-button")
  .addEventListener("click", () => toggleToolbar(false));
document.getElementById("show-dialog").addEventListener("click", () => toggleStackDialog());
const stacktraceDialog = document.getElementById("phxprof--stacktrace");
document.getElementById("close-dialog").addEventListener("click", () => stacktraceDialog.close());
stacktraceDialog.addEventListener("click", (e) => {
  if (e.target === stacktraceDialog) stacktraceDialog.close();
});

toggleToolbar(localStorage.getItem(SHOW) === "true");

window.getPhxProfToken = () => toolbar.dataset.token;

// ─── Query table sorting ────────────────────────────────────────────

let querySort = { col: "count", dir: "desc" };

function sortQueryList(col) {
  const list = document.getElementById("query_list");
  if (!list) return;

  const rows = Array.from(list.querySelectorAll(".phxprof-query-row"));
  if (rows.length === 0) return;

  if (querySort.col === col) {
    querySort.dir = querySort.dir === "asc" ? "desc" : "asc";
  } else {
    querySort.col = col;
    querySort.dir = "desc";
  }

  const cellClass = {
    count: ".phxprof-query-count",
    time: ".phxprof-query-time",
    data: ".phxprof-query-data",
  }[col];

  rows.sort((a, b) => {
    const av = parseFloat(a.querySelector(cellClass)?.dataset.sortValue ?? 0);
    const bv = parseFloat(b.querySelector(cellClass)?.dataset.sortValue ?? 0);
    return querySort.dir === "asc" ? av - bv : bv - av;
  });

  rows.forEach((r) => list.appendChild(r));
  updateSortHeaders();
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
