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

  function seat(id) {
    try { return JSON.parse(window.localStorage.getItem('dots-seat-' + id)); } catch (err) { return null; }
  }

  /* The game id a share link carries: /dots/#g=<id>. */
  function linkedGame() {
    var m = /^#g=([a-f0-9]{12})$/.exec(location.hash);
    return m ? m[1] : null;
  }

  function shareLink(id) {
    return location.origin + location.pathname + '#g=' + id;
  }

  function create(opts, done) {
    post({ 'do': 'create', w: opts.w, h: opts.h, name: opts.name, color: opts.color,
           listed: opts.listed ? 1 : 0 },
      function (err, body) {
        if (err) { done(err); return; }
        saveSeat(body.id, { token: body.token, side: 0 });
        done(null, { id: body.id, link: shareLink(body.id) });
      });
  }

  /* done(error, game) with the game as dots.pl stores it. */
  function load(id, done) {
    var failed = function () { done('The server did not answer. Try again.'); };
    fetch(ENDPOINT + '?id=' + id, { cache: 'no-store' })
      .then(function (res) {
        return res.json().then(function (body) {
          if (res.status === 404) done('That game is gone. Games are cleared out after a while.');
          else done(res.ok ? null : (body.error || 'The server said no.'), body);
        }, failed);
      }, failed);
  }

  function join(id, opts, done) {
    post({ 'do': 'join', id: id, name: opts.name, color: opts.color }, function (err, body) {
      if (err) { done(err); return; }
      saveSeat(id, { token: body.token, side: 1 });
      done(null);
    });
  }

  function move(id, token, edge, done) {
    post({ 'do': 'move', id: id, token: token, edge: edge }, function (err) { done(err); });
  }

  window.DotsNet = { create: create, load: load, join: join, move: move, seat: seat,
                     linkedGame: linkedGame, shareLink: shareLink };
}());
