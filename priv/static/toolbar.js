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

toggleToolbar(localStorage.getItem(SHOW) === "true");

window.getPhxProfToken = () => toolbar.dataset.token;
