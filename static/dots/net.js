/* DOTS across the internet — the browser's side of dots.pl. Everything that
   talks to the server lives here, so game.js keeps to the game. */

(function () {
  "use strict";

  var ENDPOINT = 'dots.pl';

  /* POST to dots.pl; done(error, body). error is null on success, otherwise
     a sentence fit for the message line. */
  function post(params, done) {
    var failed = function () { done('The server did not answer. Try again.'); };
    fetch(ENDPOINT + '?' + new URLSearchParams(params), { method: 'POST', cache: 'no-store' })
      .then(function (res) {
        return res.json().then(function (body) {
          done(res.ok ? null : (body.error || 'The server said no.'), body);
        }, failed);
      }, failed);
  }

  /* Each seat's token lives with the game id, so a reload can take it back.
     Storage may be missing (private windows) — then a reload loses the seat. */
  function saveSeat(id, seat) {
    try { window.localStorage.setItem('dots-seat-' + id, JSON.stringify(seat)); } catch (err) { /* no storage */ }
  }

  function shareLink(id) {
    return location.origin + location.pathname + '#g=' + id;
  }

  function create(opts, done) {
    post({ 'do': 'create', w: opts.w, h: opts.h, name: opts.name, color: opts.color },
      function (err, body) {
        if (err) { done(err); return; }
        saveSeat(body.id, { token: body.token, side: 0 });
        done(null, { id: body.id, link: shareLink(body.id) });
      });
  }

  window.DotsNet = { create: create };
}());
