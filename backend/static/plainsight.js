/*! plainsight.js — privacy-first analytics (~50 lines, no cookies, no PII).
 * Install: <script defer src="https://YOUR-BACKEND/js/script.js" data-site="SITE_KEY"></script>
 * Sends text/plain JSON via sendBeacon => a CORS simple request, no preflight.
 * Honors Do Not Track. Counts SPA navigations via pushState/popstate hooks. */
(function () {
  "use strict";
  var script = document.currentScript;
  if (!script) return;
  var siteKey = script.getAttribute("data-site");
  if (!siteKey) return;
  if (navigator.doNotTrack === "1" || window.doNotTrack === "1") return;
  var host = location.hostname;
  if (
    (host === "localhost" || host === "127.0.0.1") &&
    !script.hasAttribute("data-allow-localhost")
  )
    return;

  var endpoint = new URL(script.src).origin + "/collect";
  var lastPath = null;

  function send() {
    var path = location.pathname + location.search;
    if (path === lastPath) return; // dedupe replays of the same view
    lastPath = path;
    var payload = JSON.stringify({
      s: siteKey,
      u: path,
      r: document.referrer || "",
      w: window.innerWidth || 0,
    });
    if (navigator.sendBeacon) {
      navigator.sendBeacon(endpoint, payload); // string body => text/plain
    } else {
      fetch(endpoint, {
        method: "POST",
        body: payload,
        keepalive: true,
        headers: { "Content-Type": "text/plain" },
      });
    }
  }

  // SPA route changes (Flutter web, React, etc.) never reload the page —
  // hook pushState + popstate so each in-app navigation counts.
  var timer = null;
  function queue() {
    clearTimeout(timer);
    timer = setTimeout(send, 100);
  }
  var origPush = history.pushState;
  history.pushState = function () {
    origPush.apply(this, arguments);
    queue();
  };
  window.addEventListener("popstate", queue);

  send();
})();
