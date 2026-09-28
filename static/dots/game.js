/* DOTS — a browser port of DOTS7.PAS, written by Robert Nugen in Feb 1990.
   The rules, the keys, the EGA colours, the marker squashing itself flat
   against the wall and grunting about it: all of that is the Pascal. What is
   new is tap-to-draw, a computer opponent, and a grid that resizes.
   Version 1.1 */

(function () {
  "use strict";

  /* The 16 EGA colours in the order COLORSET listed them. Players choose from
     1..15 — Black is the board, as GetPlayerColor's 1..MaxColor implied. */
  var COLORSET = [
    ['Black', '#000000'],       ['Blue', '#0000AA'],
    ['Green', '#00AA00'],       ['Cyan', '#00AAAA'],
    ['Red', '#AA0000'],         ['Magenta', '#AA00AA'],
    ['Brown', '#AA5500'],       ['Light Gray', '#AAAAAA'],
    ['Dark Gray', '#555555'],   ['Light Blue', '#5555FF'],
    ['Light Green', '#55FF55'], ['Light Cyan', '#55FFFF'],
    ['Light Red', '#FF5555'],   ['Light Magenta', '#FF55FF'],
    ['Yellow', '#FFFF55'],      ['White', '#FFFFFF']
  ];
  var DOTCOLOR = 15, LINECOLOR = 3, MARKERCOLOR = 14, MAXCOLOR = 15;
  var MAXBOXES = 30;                       /* GetNum accepted 0..30 a side */

  /* Line[1..4] on each box, in the Pascal's order. */
  var SIDE = { left: 1, up: 2, right: 3, down: 4 };

  var DIRS = {
    up: [0, 1],    down: [0, -1],  left: [-1, 0],  right: [1, 0],
    ul: [-1, 1],   ur: [1, 1],     dl: [-1, -1],   dr: [1, -1]
  };

  /* The scripted game the title screen plays with itself. Straight from
     TitleScreen's MINIGAME: 71..81 are moves, 172..180 are 100 + a draw key. */
  var MINIGAME = [172, 77, 72, 172, 175, 75, 80, 177, 77, 177, 71, 172, 175, 80,
                  175, 180, 77, 72, 177, 180, 80, 180, 72, 75, 80, 77, 72, 75];
  var SCANCODE = { 71: 'ul', 72: 'up', 73: 'ur', 75: 'left',
                   77: 'right', 79: 'dl', 80: 'down', 81: 'dr' };
  var SCANSIDE = { 72: SIDE.up, 75: SIDE.left, 77: SIDE.right, 80: SIDE.down };

  var el = {
    stages: {
      title: document.getElementById('stage-title'),
      setup: document.getElementById('stage-setup'),
      join: document.getElementById('stage-join'),
      game: document.getElementById('stage-game')
    },
    demo: document.getElementById('demo'),
    board: document.getElementById('board'),
    begin: document.getElementById('btn-begin'),
    setupForm: document.getElementById('setup'),
    setupMsg: document.getElementById('setup-msg'),
    gameMsg: document.getElementById('game-msg'),
    verdict: document.getElementById('verdict'),
    scores: [document.getElementById('score1'), document.getElementById('score2')],
    names: [document.getElementById('p1name'), document.getElementById('p2name')],
    chosen: [document.getElementById('p1chosen'), document.getElementById('p2chosen')],
    swatches: [document.getElementById('p1colors'), document.getElementById('p2colors')],
    kind: document.getElementById('p2kind'),
    hereOnly: document.querySelectorAll('.here-only'),
    netOnly: document.querySelectorAll('.net-only'),
    listed: document.getElementById('listed'),
    lobby: { waiting: document.getElementById('lobby-waiting'),
             playing: document.getElementById('lobby-playing'),
             done: document.getElementById('lobby-done') },
    lobbyMsg: document.getElementById('lobby-msg'),
    play: document.querySelector('#setup button[type=submit]'),
    joinForm: document.getElementById('join'),
    joinWho: document.getElementById('join-who'),
    joinSeat: document.getElementById('join-seat'),
    joinName: document.getElementById('jname'),
    joinChosen: document.getElementById('jchosen'),
    joinColors: document.getElementById('jcolors'),
    joinMsg: document.getElementById('join-msg'),
    joinBtn: document.getElementById('btn-join'),
    width: document.getElementById('width'),
    height: document.getElementById('height'),
    help: document.getElementById('help'),
    helpPages: [document.getElementById('help-1'), document.getElementById('help-2'),
                document.getElementById('help-3')],
    ask: document.getElementById('ask'),
    askQ: document.getElementById('ask-q'),
    sound: document.getElementById('btn-sound'),
    again: document.getElementById('btn-again')
  };

  var game = null;       /* the game being played */
  var demo = null;       /* the title screen playing with itself */
  var colors = [12, 9];  /* Light Red and Light Blue, the Auto defaults */
  var overlay = null;    /* 'help' or 'ask' while one is open */
  var helpPage = 0;      /* rules, then the two credits screens */
  var askAnswer = null;  /* what to run when a Y/N box is answered */
  var msgTimer = null;

  function hex(c) { return COLORSET[c][1]; }
  function clamp(n, lo, hi) { return n < lo ? lo : (n > hi ? hi : n); }
  function calm() {
    return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  /* ---------- sound ----------
     The PC speaker had Sound(freq) and NoSound; a square wave is the nearest
     thing a browser has. Grunt's count*count*count+20 lands between 21 and
     145 Hz, so the low end gets a floor — a phone speaker cannot move that
     slowly, and a silent grunt is no grunt at all. */

  var audio = { on: true, ctx: null };

  function beep(freq, ms) {
    if (!audio.on) return;
    try {
      if (!audio.ctx) {
        var AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) { audio.on = false; return; }
        audio.ctx = new AC();
      }
      if (audio.ctx.state === 'suspended') audio.ctx.resume();
      var osc = audio.ctx.createOscillator(), gain = audio.ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = freq;
      gain.gain.value = 0.05;
      osc.connect(gain);
      gain.connect(audio.ctx.destination);
      var t = audio.ctx.currentTime;
      osc.start(t);
      osc.stop(t + ms / 1000);
    } catch (err) {
      audio.on = false;
    }
  }

  function buzz(g) { if (!g || !g.silent) beep(250, 20); }
  function grunt(g, count) { if (!g.silent) beep(Math.max(70, count * count * count + 20), 20); }

  /* ---------- the board ---------- */

  function makeGame(canvas, w, h, players) {
    var boxes = [], x, y;
    /* Padded to 0..w+1 so adding a side to an off-grid neighbour is harmless,
       exactly as the Pascal's array[0..32,0..32] allowed. */
    for (x = 0; x <= w + 1; x++) {
      boxes[x] = [];
      for (y = 0; y <= h + 1; y++) {
        boxes[x][y] = { line: [false, false, false, false, false], sides: 0,
                        filled: false, color: 0 };
      }
    }
    return {
      canvas: canvas, ctx: canvas.getContext('2d'),
      w: w, h: h, boxes: boxes, players: players,
      turn: 0, scores: [0, 0], taken: 0, numBoxes: w * h, done: false,
      marker: { x: 1, y: 1 }, squash: null,
      armed: false, busy: false, thinking: false, silent: false,
      cell: 0, x0: 0, y0: 0, cssW: 0, cssH: 0
    };
  }

  /* DesignBoard fitted square cells into the play area and centred them.
     Here the play area is the canvas, so it is the same idea without the
     EGA-specific rounding. */
  function layout(g, fitHeight) {
    var dpr = window.devicePixelRatio || 1;
    var pad = 14;
    var cw = Math.max(1, Math.round(g.canvas.getBoundingClientRect().width));
    var ch, cell;

    if (fitHeight) {
      /* Square cells, so the canvas takes only the height the grid needs
         rather than leaving a field of black under a small board. */
      var maxH = Math.min(window.innerHeight * 0.72, 34 * 16);
      cell = Math.max(6, Math.min((cw - 2 * pad) / g.w, (maxH - 2 * pad) / g.h));
      ch = Math.round(cell * g.h + 2 * pad);
      g.canvas.style.height = ch + 'px';
    } else {
      ch = Math.max(1, Math.round(g.canvas.getBoundingClientRect().height));
      cell = Math.max(6, Math.min((cw - 2 * pad) / g.w, (ch - 2 * pad) / g.h));
    }

    g.canvas.width = Math.round(cw * dpr);
    g.canvas.height = Math.round(ch * dpr);
    g.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.cssW = cw;
    g.cssH = ch;
    g.cell = cell;
    g.x0 = (cw - cell * g.w) / 2;
    g.y0 = (ch + cell * g.h) / 2;      /* row 1 sits at the bottom */
  }

  function dotXY(g, x, y) {
    return { x: g.x0 + (x - 1) * g.cell, y: g.y0 - (y - 1) * g.cell };
  }

  /* ---------- drawing ---------- */

  function draw(g) {
    var c = g.ctx, x, y, b, a, d, p;
    c.clearRect(0, 0, g.cssW, g.cssH);

    for (x = 1; x <= g.w; x++) {
      for (y = 1; y <= g.h; y++) {
        b = g.boxes[x][y];
        if (!b.filled) continue;
        a = dotXY(g, x, y);
        d = dotXY(g, x + 1, y + 1);
        c.fillStyle = hex(b.color);
        c.fillRect(a.x + 1, d.y + 1, (d.x - a.x) - 2, (a.y - d.y) - 2);
      }
    }

    c.strokeStyle = hex(LINECOLOR);
    c.lineWidth = clamp(g.cell * 0.035, 2, 5);
    c.lineCap = 'round';
    c.beginPath();
    for (x = 1; x <= g.w; x++) {
      for (y = 1; y <= g.h; y++) {
        b = g.boxes[x][y];
        if (b.line[SIDE.left]) segment(c, g, x, y + 1, x, y);
        if (b.line[SIDE.up]) segment(c, g, x, y + 1, x + 1, y + 1);
        if (b.line[SIDE.right]) segment(c, g, x + 1, y + 1, x + 1, y);
        if (b.line[SIDE.down]) segment(c, g, x, y, x + 1, y);
      }
    }
    c.stroke();

    /* DrawDots used PutPixel; one pixel is invisible on a screen this dense. */
    c.fillStyle = hex(DOTCOLOR);
    var r = clamp(g.cell * 0.03, 1.5, 4);
    for (x = 1; x <= g.w + 1; x++) {
      for (y = 1; y <= g.h + 1; y++) {
        p = dotXY(g, x, y);
        c.fillRect(p.x - r, p.y - r, r * 2, r * 2);
      }
    }

    drawMarker(g);
  }

  function segment(c, g, x1, y1, x2, y2) {
    var a = dotXY(g, x1, y1), b = dotXY(g, x2, y2);
    c.moveTo(a.x, a.y);
    c.lineTo(b.x, b.y);
  }

  /* DrawMarker drew the two diagonals of the cell — an X across the box. */
  function drawMarker(g) {
    var c = g.ctx, r = markerRect(g);
    c.strokeStyle = hex(MARKERCOLOR);
    c.lineWidth = clamp(g.cell * (g.armed ? 0.06 : 0.03), 1.5, g.armed ? 8 : 4);
    c.beginPath();
    c.moveTo(r.left, r.bottom);
    c.lineTo(r.right, r.top);
    c.moveTo(r.left, r.top);
    c.lineTo(r.right, r.bottom);
    c.stroke();
  }

  /* DrawSquashedMarker pinned the marker to whichever wall it walked into and
     shrank it toward that wall. SquashDir is laid out like a number pad. */
  function markerRect(g) {
    var a = dotXY(g, g.marker.x, g.marker.y);
    var b = dotXY(g, g.marker.x + 1, g.marker.y + 1);
    var r = { left: a.x + 1, right: b.x - 1, top: b.y + 1, bottom: a.y - 1 };
    if (!g.squash) return r;
    var f = g.squash.frac, dir = g.squash.dir;
    var wide = r.right - r.left, tall = r.bottom - r.top;
    if (dir === 4 || dir === 1 || dir === 7) r.right = r.left + wide * f;
    if (dir === 6 || dir === 3 || dir === 9) r.left = r.right - wide * f;
    if (dir === 8 || dir === 7 || dir === 9) r.bottom = r.top + tall * f;
    if (dir === 2 || dir === 1 || dir === 3) r.top = r.bottom - tall * f;
    return r;
  }

  /* UnSquashIt: five steps flat against the wall and five back out, grunting
     down the scale and up again. The Pascal ran as fast as its 20ms Sound()
     calls allowed; 45ms a step reads about the same away from a CGA monitor. */
  function squashMarker(g, dir, done) {
    var steps = 5, seq = [], i, n = 0;
    for (i = steps; i >= 1; i--) seq.push(i);
    for (i = 1; i <= steps; i++) seq.push(i);
    if (calm()) { g.squash = null; draw(g); if (done) done(); return; }
    g.busy = true;
    (function step() {
      if (n >= seq.length) {
        g.squash = null;
        g.busy = false;
        draw(g);
        if (done) done();
        return;
      }
      g.squash = { dir: dir, frac: seq[n] / steps };
      draw(g);
      grunt(g, seq[n]);
      n++;
      window.setTimeout(step, 45);
    }());
  }

  /* ---------- moving and drawing lines ---------- */

  /* MoveMarker: eight directions, and walking into the edge of the grid
     squashes the marker against it rather than moving. A diagonal that only
     leaves the grid on one axis still travels along the other. */
  function move(g, dir, done) {
    var d = DIRS[dir];
    var x = g.marker.x + d[0], y = g.marker.y + d[1], hx = 0, hy = 0;
    if (x < 1) { x = 1; hx = -1; } else if (x > g.w) { x = g.w; hx = 1; }
    if (y < 1) { y = 1; hy = -1; } else if (y > g.h) { y = g.h; hy = 1; }
    g.marker = { x: x, y: y };
    if (hx || hy) {
      squashMarker(g, squashDir(hx, hy), done);
      return;
    }
    draw(g);
    if (done) done();
  }

  function squashDir(hx, hy) {
    if (hx && hy) return hy > 0 ? (hx < 0 ? 7 : 9) : (hx < 0 ? 1 : 3);
    if (hx) return hx < 0 ? 4 : 6;
    return hy > 0 ? 8 : 2;
  }

  function addSide(g, x, y, side) {
    var b = g.boxes[x] && g.boxes[x][y];
    if (!b || b.line[side]) return;
    b.line[side] = true;
    b.sides++;
  }

  /* SeeIfAddSideOK. Returns false — and buzzes — when the line is already
     drawn, which is what AddOk staying false meant. */
  function play(g, side) {
    if (!place(g, side)) { buzz(g); return false; }
    draw(g);
    return true;
  }

  /* The rules of one line, with no sound or drawing, so a game sent by the
     server can be replayed from its list of moves. */
  function place(g, side) {
    var x = g.marker.x, y = g.marker.y, b = g.boxes[x][y];
    if (!side || b.line[side]) return false;
    addSide(g, x, y, side);
    if (side === SIDE.left) addSide(g, x - 1, y, SIDE.right);
    if (side === SIDE.up) addSide(g, x, y + 1, SIDE.down);
    if (side === SIDE.right) addSide(g, x + 1, y, SIDE.left);
    if (side === SIDE.down) addSide(g, x, y - 1, SIDE.up);
    if (!checkForBox(g)) switchPlayers(g);
    return true;
  }

  /* CheckForBox swept the 3x3 around the marker, which catches both boxes a
     single line can finish. */
  function checkForBox(g) {
    var one = false, dx, dy, x, y, b;
    for (dx = -1; dx <= 1; dx++) {
      for (dy = -1; dy <= 1; dy++) {
        x = g.marker.x + dx;
        y = g.marker.y + dy;
        if (x < 1 || x > g.w || y < 1 || y > g.h) continue;
        b = g.boxes[x][y];
        if (b.sides === 4 && !b.filled) {
          b.filled = true;
          b.color = g.players[g.turn].color;
          g.taken++;
          g.scores[g.turn]++;
          if (g.taken === g.numBoxes) g.done = true;
          one = true;
        }
      }
    }
    return one;
  }

  function switchPlayers(g) { g.turn = g.turn ? 0 : 1; }

  /* ---------- the computer player ----------
     Edges get a name of their own here so the two boxes either side of one
     are easy to reach: 'h,x,y' is the line under box (x,y) and over box
     (x,y-1); 'v,x,y' is the line left of box (x,y) and right of (x-1,y). */

  function allEdges(w, h) {
    var keys = [], x, y;
    for (x = 1; x <= w; x++) for (y = 1; y <= h + 1; y++) keys.push('h,' + x + ',' + y);
    for (x = 1; x <= w + 1; x++) for (y = 1; y <= h; y++) keys.push('v,' + x + ',' + y);
    return keys;
  }

  function edgeBoxes(key, w, h) {
    var p = key.split(','), x = +p[1], y = +p[2], pair;
    pair = p[0] === 'h' ? [[x, y - 1], [x, y]] : [[x - 1, y], [x, y]];
    return pair.filter(function (c) {
      return c[0] >= 1 && c[0] <= w && c[1] >= 1 && c[1] <= h;
    });
  }

  /* The other way round: the edge a side of the marker's box is. */
  function edgeKey(x, y, side) {
    if (side === SIDE.left) return 'v,' + x + ',' + y;
    if (side === SIDE.right) return 'v,' + (x + 1) + ',' + y;
    if (side === SIDE.down) return 'h,' + x + ',' + y;
    return 'h,' + x + ',' + (y + 1);
  }

  /* Which box the marker has to stand in, and which of its sides to draw. */
  function edgeToMove(key, w, h) {
    var p = key.split(','), x = +p[1], y = +p[2];
    if (p[0] === 'h') {
      return y <= h ? { x: x, y: y, side: SIDE.down } : { x: x, y: y - 1, side: SIDE.up };
    }
    return x <= w ? { x: x, y: y, side: SIDE.left } : { x: x - 1, y: y, side: SIDE.right };
  }

  function aiState(g) {
    var st = { w: g.w, h: g.h, taken: {}, sides: [], filled: [] }, x, y, b;
    for (x = 0; x <= g.w + 1; x++) {
      st.sides[x] = [];
      st.filled[x] = [];
      for (y = 0; y <= g.h + 1; y++) {
        st.sides[x][y] = g.boxes[x][y].sides;
        st.filled[x][y] = g.boxes[x][y].filled;
      }
    }
    for (x = 1; x <= g.w; x++) {
      for (y = 1; y <= g.h; y++) {
        b = g.boxes[x][y];
        if (b.line[SIDE.left]) st.taken['v,' + x + ',' + y] = true;
        if (b.line[SIDE.right]) st.taken['v,' + (x + 1) + ',' + y] = true;
        if (b.line[SIDE.down]) st.taken['h,' + x + ',' + y] = true;
        if (b.line[SIDE.up]) st.taken['h,' + x + ',' + (y + 1)] = true;
      }
    }
    return st;
  }

  function applyEdge(st, key) {
    var boxes = edgeBoxes(key, st.w, st.h), i, c, made = 0, three = [];
    st.taken[key] = true;
    for (i = 0; i < boxes.length; i++) {
      c = boxes[i];
      st.sides[c[0]][c[1]]++;
      if (st.sides[c[0]][c[1]] === 4 && !st.filled[c[0]][c[1]]) {
        st.filled[c[0]][c[1]] = true;
        made++;
      } else if (st.sides[c[0]][c[1]] === 3) {
        three.push(c);
      }
    }
    return { made: made, three: three };
  }

  function freeEdge(st, x, y) {
    var keys = ['h,' + x + ',' + y, 'h,' + x + ',' + (y + 1),
                'v,' + x + ',' + y, 'v,' + (x + 1) + ',' + y], i;
    for (i = 0; i < keys.length; i++) if (!st.taken[keys[i]]) return keys[i];
    return null;
  }

  /* How many boxes an opponent who just takes everything on offer would get. */
  function greedyTake(st) {
    var got = 0, queue = [], x, y, i, cell, key, done;
    for (x = 1; x <= st.w; x++) {
      for (y = 1; y <= st.h; y++) {
        if (st.sides[x][y] === 3 && !st.filled[x][y]) queue.push([x, y]);
      }
    }
    while (queue.length) {
      cell = queue.pop();
      if (st.filled[cell[0]][cell[1]] || st.sides[cell[0]][cell[1]] !== 3) continue;
      key = freeEdge(st, cell[0], cell[1]);
      if (!key) continue;
      done = applyEdge(st, key);
      got += done.made;
      for (i = 0; i < done.three.length; i++) queue.push(done.three[i]);
    }
    return got;
  }

  function shuffled(list) {
    var a = list.slice(), i, j, t;
    for (i = a.length - 1; i > 0; i--) {
      j = Math.floor(Math.random() * (i + 1));
      t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }

  function aiPick(g) {
    var st = aiState(g), free = [], keys = allEdges(g.w, g.h), i, k, boxes, j, c;
    for (i = 0; i < keys.length; i++) if (!st.taken[keys[i]]) free.push(keys[i]);
    if (!free.length) return null;
    free = shuffled(free);

    var safe = [];
    for (i = 0; i < free.length; i++) {
      k = free[i];
      boxes = edgeBoxes(k, g.w, g.h);
      var completes = false, gives = false;
      for (j = 0; j < boxes.length; j++) {
        c = boxes[j];
        if (st.sides[c[0]][c[1]] === 3) completes = true;
        if (st.sides[c[0]][c[1]] === 2) gives = true;
      }
      if (completes) return edgeToMove(k, g.w, g.h);   /* a box for free */
      if (!gives) safe.push(k);
    }
    if (safe.length) return edgeToMove(safe[0], g.w, g.h);

    /* Everything hands something over, so hand over as little as possible.
       Big grids get a sample rather than the whole list. */
    var tries = free.slice(0, 60), best = free[0], cost = Infinity, c2;
    for (i = 0; i < tries.length; i++) {
      var probe = aiState(g);
      applyEdge(probe, tries[i]);
      c2 = greedyTake(probe);
      if (c2 < cost) { cost = c2; best = tries[i]; }
    }
    return edgeToMove(best, g.w, g.h);
  }

  /* ---------- panel ---------- */

  function updateScores(g) {
    var i, row, p;
    for (i = 0; i < 2; i++) {
      row = el.scores[i];
      p = g.players[i];
      row.style.color = hex(p.color);
      row.querySelector('.name').textContent = p.name;
      row.querySelector('.num').textContent = g.scores[i];
      row.classList.toggle('up', !g.done && g.turn === i);
    }
  }

  function message(text) {
    el.gameMsg.textContent = text || restingMessage();
    if (msgTimer) window.clearTimeout(msgTimer);
    if (text) {
      msgTimer = window.setTimeout(function () { el.gameMsg.textContent = restingMessage(); }, 4000);
    }
  }

  /* What the message line settles back to: blank, except for a spectator. */
  function restingMessage() {
    return game && game.net && game.net.side < 0 && !game.done ? 'Watching.' : '';
  }

  /* DisplayWinner */
  function finish(g) {
    var i;
    if (g.scores[0] === g.scores[1]) {
      el.verdict.textContent = 'Wow!! A Tie';
      el.verdict.style.color = hex(MARKERCOLOR);
    } else {
      i = g.scores[0] > g.scores[1] ? 0 : 1;
      el.verdict.textContent = g.players[i].name + ' WINS ! !';
      el.verdict.style.color = hex(g.players[i].color);
    }
    el.verdict.hidden = false;
    el.again.hidden = false;
    g.armed = false;
    updateScores(g);
    draw(g);
  }

  /* One move, from either player, with everything the panel has to say. */
  function commit(g, side) {
    var key = g.net && edgeKey(g.marker.x, g.marker.y, side);
    if (g.net && g.net.side < 0) {
      message('You are watching.');
      buzz(g);
      return false;
    }
    if (g.net && (g.net.sending || g.turn !== g.net.side)) {
      message('Wait for ' + g.players[g.turn].name + '. .');
      buzz(g);
      return false;
    }
    if (!play(g, side)) {
      message('There is already a line there.');
      return false;
    }
    g.armed = false;
    message('');
    updateScores(g);
    draw(g);
    if (g.net) sendMove(g, key);
    if (g.done) { finish(g); return true; }
    think(g);
    return true;
  }

  function think(g) {
    if (g.done || g.players[g.turn].kind !== 'computer') { g.thinking = false; return; }
    g.thinking = true;
    window.setTimeout(function () {
      if (g.done) { g.thinking = false; return; }
      var m = aiPick(g);
      g.thinking = false;
      if (!m) return;
      g.marker = { x: m.x, y: m.y };
      commit(g, m.side);
    }, 420);
  }

  /* ---------- input ---------- */

  function keyDir(e) {
    switch (e.key) {
      case 'ArrowUp': return 'up';
      case 'ArrowDown': return 'down';
      case 'ArrowLeft': return 'left';
      case 'ArrowRight': return 'right';
    }
    switch (e.code) {           /* the number pad, NumLock either way */
      case 'Numpad8': return 'up';
      case 'Numpad2': return 'down';
      case 'Numpad4': return 'left';
      case 'Numpad6': return 'right';
      case 'Numpad7': return 'ul';
      case 'Numpad9': return 'ur';
      case 'Numpad1': return 'dl';
      case 'Numpad3': return 'dr';
    }
    switch (e.key.toLowerCase()) {
      case 'q': return 'ul';
      case 'e': return 'ur';
      case 'z': return 'dl';
      case 'c': return 'dr';
    }
    return null;
  }

  function onKeyDown(e) {
    if (e.altKey || e.ctrlKey || e.metaKey) return;

    if (overlay === 'help') {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); helpNext(); }
      else if (e.key === 'Escape') { e.preventDefault(); closeHelp(); }
      return;
    }
    if (overlay === 'ask') {
      if (e.key.toLowerCase() === 'y') { e.preventDefault(); answerAsk(true); }
      else if (e.key.toLowerCase() === 'n' || e.key === 'Escape') { e.preventDefault(); answerAsk(false); }
      return;
    }

    if (!el.stages.title.hidden) {
      e.preventDefault();
      showSetup();
      return;
    }
    if (!el.stages.setup.hidden || !el.stages.join.hidden) {
      if (e.key === 'F1') { e.preventDefault(); openHelp(); }
      return;
    }

    var g = game;
    if (!g || g.busy || g.thinking) return;
    if (document.activeElement && document.activeElement.tagName === 'BUTTON'
        && (e.key === 'Enter' || e.key === ' ')) return;

    var dir = keyDir(e);

    if (g.done) {
      /* PlayingMainGame was false here: the marker still moves, Enter or Esc
         ends it. On the web, ending it means another game. */
      if (dir) { e.preventDefault(); move(g, dir); return; }
      if (e.key === 'Enter' || e.key === 'Escape') { e.preventDefault(); showSetup(); }
      return;
    }

    if (g.armed) {
      /* GetBufferedInput([27,72,75,77,80]) — Esc, or one of the four sides. */
      if (dir && SIDE[dir]) { e.preventDefault(); commit(g, SIDE[dir]); return; }
      if (e.key === 'Escape') {
        e.preventDefault();
        g.armed = false;
        message('');
        draw(g);
        return;
      }
      if (dir) { e.preventDefault(); buzz(g); }
      return;
    }

    if (dir) { e.preventDefault(); move(g, dir); return; }

    switch (e.key) {
      case 'Enter':
        e.preventDefault();
        g.armed = true;
        message('Now an arrow key, for the side to draw.');
        draw(g);
        break;
      case 'Escape':
        e.preventDefault();
        askQuit();
        break;
      case 'F1':
        e.preventDefault();
        openHelp();
        break;
      default:
        switch (e.key.toLowerCase()) {
          case 'h':
          case '?':
            e.preventDefault();
            openHelp();
            break;
          case 's':
            e.preventDefault();
            askSwitch();
            break;
        }
    }
  }

  /* Tap or click: near a gap between two dots, draw that line; anywhere else
     in a box, move the marker there. */
  function onBoardClick(e) {
    var g = game;
    if (!g || g.busy || g.thinking || g.done) return;
    var rect = g.canvas.getBoundingClientRect();
    var fx = (e.clientX - rect.left - g.x0) / g.cell + 1;
    var fy = (g.y0 - (e.clientY - rect.top)) / g.cell + 1;
    var x = clamp(Math.floor(fx), 1, g.w), y = clamp(Math.floor(fy), 1, g.h);
    var u = clamp(fx - x, 0, 1), v = clamp(fy - y, 0, 1);
    var near = [[u, 'left'], [1 - u, 'right'], [v, 'down'], [1 - v, 'up']];
    near.sort(function (a, b) { return a[0] - b[0]; });

    g.marker = { x: x, y: y };
    g.armed = false;
    message('');
    if (near[0][0] <= 0.3) commit(g, SIDE[near[0][1]]);
    else draw(g);
  }

  /* ---------- overlays ---------- */

  /* The Pascal showed its rules screen, then Enter turned to the credits.
     Here the credits run to two pages, marked 1/2 and 2/2. */
  function openHelp() {
    overlay = 'help';
    helpPage = 0;
    el.help.hidden = false;
    showHelpPage();
  }

  function showHelpPage() {
    var i, btn;
    for (i = 0; i < el.helpPages.length; i++) el.helpPages[i].hidden = i !== helpPage;
    btn = el.helpPages[helpPage].querySelector('.more button');
    if (btn) btn.focus();
  }

  function helpNext() {
    if (helpPage >= el.helpPages.length - 1) { closeHelp(); return; }
    helpPage++;
    showHelpPage();
  }

  function closeHelp() {
    el.help.hidden = true;
    overlay = null;
    if (game && !el.stages.game.hidden) draw(game);
  }

  function ask(question, onYes) {
    overlay = 'ask';
    askAnswer = onYes;
    el.askQ.innerHTML = question;
    el.ask.hidden = false;
    buzz(null);                       /* WriteMessage always buzzed first */
    document.getElementById('btn-yes').focus();
  }

  function answerAsk(yes) {
    var fn = askAnswer;
    el.ask.hidden = true;
    overlay = null;
    askAnswer = null;
    if (yes && fn) fn();
  }

  function askQuit() {
    ask('Do you want to Quit?<br>Y/N', function () { showTitle(); });
  }

  function askSwitch() {
    var g = game;
    if (g.net) {
      message('Players cannot trade places across the internet.');
      buzz(g);
      return;
    }
    if (g.players[1].kind === 'computer') {
      message('The computer will not trade places with you.');
      buzz(g);
      return;
    }
    ask("Press 'Y' to<br>switch players. .", function () {
      switchPlayers(g);
      updateScores(g);
      draw(g);
    });
  }

  /* ---------- setup screen ---------- */

  function buildSwatches() {
    var i, p, btn;
    for (p = 0; p < 2; p++) {
      el.swatches[p].innerHTML = '';
      for (i = 1; i <= MAXCOLOR; i++) {
        btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'swatch';
        btn.style.background = hex(i);
        btn.setAttribute('role', 'radio');
        btn.setAttribute('aria-label', COLORSET[i][0]);
        btn.setAttribute('aria-checked', 'false');
        btn.dataset.player = p;
        btn.dataset.color = i;
        el.swatches[p].appendChild(btn);
      }
    }
    document.addEventListener('click', function (e) {
      var t = e.target;
      if (!t.classList || !t.classList.contains('swatch') || !t.dataset.player) return;
      pickColor(+t.dataset.player, +t.dataset.color);
    });
    showColors();
  }

  function pickColor(player, color) {
    if (player === 1 && color === colors[0]) {
      /* "Be original." — GetPlayerColor would not let player two have it. */
      el.setupMsg.textContent = 'Be original. ' + playerName(0) + ' already got '
        + COLORSET[colors[0]][0] + '.';
      buzz(null);
      return;
    }
    if (player === 0 && color === colors[1]) colors[1] = nextColor(color);
    colors[player] = color;
    el.setupMsg.textContent = '';
    showColors();
  }

  /* The next colour round the wheel that is not the one just taken. */
  function nextColor(taken) {
    var c = taken % MAXCOLOR + 1;
    return c === taken ? (c % MAXCOLOR + 1) : c;
  }

  function showColors() {
    var p, i, kids;
    for (p = 0; p < 2; p++) {
      el.chosen[p].textContent = COLORSET[colors[p]][0];
      el.chosen[p].style.color = hex(colors[p]);
      kids = el.swatches[p].children;
      for (i = 0; i < kids.length; i++) {
        kids[i].setAttribute('aria-checked', +kids[i].dataset.color === colors[p] ? 'true' : 'false');
      }
    }
  }

  function playerName(i) {
    var name = el.names[i].value.trim().slice(0, 15);
    return name || (i === 0 ? 'One' : 'Two');
  }

  function readSize(input) {
    var n = parseInt(input.value, 10);
    if (isNaN(n) || n < 1 || n > MAXBOXES) return null;
    return n;
  }

  /* An internet opponent picks their own name and colour when they join. */
  function onKindChange() {
    var i, away = el.kind.value === 'internet';
    for (i = 0; i < el.hereOnly.length; i++) el.hereOnly[i].hidden = away;
    for (i = 0; i < el.netOnly.length; i++) el.netOnly[i].hidden = !away;
    el.setupMsg.textContent = '';
  }

  function createNetGame(w, h) {
    el.play.disabled = true;
    el.setupMsg.textContent = 'Setting up the game. .';
    var opts = { w: w, h: h, name: playerName(0), color: colors[0], listed: el.listed.checked };
    window.DotsNet.create(opts, function (err, made) {
      el.play.disabled = false;
      if (err) { el.setupMsg.textContent = err; buzz(null); return; }
      el.setupMsg.textContent = '';
      history.replaceState(null, '', '#g=' + made.id);
      openJoin(made.id);
    });
  }

  function onSubmit(e) {
    e.preventDefault();
    var w = readSize(el.width), h = readSize(el.height);
    if (w === null || h === null) {
      el.setupMsg.textContent = 'The number must be between 1 and ' + MAXBOXES + '.';
      buzz(null);
      return;
    }
    if (el.kind.value === 'internet') { createNetGame(w, h); return; }
    if (colors[0] === colors[1]) {
      el.setupMsg.textContent = 'Be original. ' + playerName(0) + ' already got '
        + COLORSET[colors[0]][0] + '.';
      buzz(null);
      return;
    }
    el.setupMsg.textContent = '';
    startGame(w, h);
  }

  /* ---------- joining a game from a link ---------- */

  var joining = { id: null, color: 9 };

  /* Player one's colour is simply not offered, so "Be original." never
     comes up here. */
  function buildJoinSwatches(taken) {
    var i, btn;
    el.joinColors.innerHTML = '';
    for (i = 1; i <= MAXCOLOR; i++) {
      if (i === taken) continue;
      btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'swatch';
      btn.style.background = hex(i);
      btn.setAttribute('role', 'radio');
      btn.setAttribute('aria-label', COLORSET[i][0]);
      btn.dataset.color = i;
      el.joinColors.appendChild(btn);
    }
    pickJoinColor(taken === 9 ? 12 : 9);
  }

  function pickJoinColor(color) {
    var i, kids = el.joinColors.children;
    joining.color = color;
    el.joinChosen.textContent = COLORSET[color][0];
    el.joinChosen.style.color = hex(color);
    for (i = 0; i < kids.length; i++) {
      kids[i].setAttribute('aria-checked', +kids[i].dataset.color === color ? 'true' : 'false');
    }
  }

  /* "Rob's 5 x 5 game", with Rob in Rob's colour. */
  function showWho(g) {
    var who = document.createElement('span');
    who.textContent = g.players[0].name;
    who.style.color = hex(g.players[0].color);
    el.joinWho.textContent = '';
    el.joinWho.appendChild(who);
    el.joinWho.appendChild(document.createTextNode("'s " + g.w + ' x ' + g.h + ' game'));
  }

  function openJoin(id) {
    stopPoll();
    game = null;                                /* a new link replaces any game */
    show('join');
    stopDemo();
    joining.id = id;
    el.joinWho.textContent = '';
    el.joinSeat.hidden = true;
    el.joinBtn.hidden = true;
    el.joinMsg.textContent = 'Looking for the game. .';
    window.DotsNet.load(id, function (err, g) {
      if (joining.id !== id) return;            /* another link came in meanwhile */
      if (err) { el.joinMsg.textContent = err; return; }
      var seat = window.DotsNet.seat(id);
      showWho(g);
      if (seat && g.players.length > 1) {
        showNetGame(netGame(g, { id: id, token: seat.token, side: seat.side }));
      } else if (seat) {
        el.joinMsg.textContent = 'Send this link to your opponent: ' + window.DotsNet.shareLink(id)
          + '  Waiting for someone to join. .';
        waitForJoin(id, seat);
      } else if (g.players.length > 1) {
        showNetGame(netGame(g, { id: id, token: null, side: -1 }));   /* a spectator */
      } else {
        el.joinMsg.textContent = '';
        buildJoinSwatches(g.players[0].color);
        el.joinSeat.hidden = false;
        el.joinBtn.hidden = false;
      }
    });
  }

  /* Player one, holding the link open until player two arrives. */
  function waitForJoin(id, seat) {
    startPoll(function () {
      window.DotsNet.load(id, function (err, g) {
        if (joining.id !== id || el.stages.join.hidden) return;
        if (!err && g.players.length > 1) {
          showNetGame(netGame(g, { id: id, token: seat.token, side: seat.side }));
        } else {
          waitForJoin(id, seat);
        }
      });
    });
  }

  function onJoin(e) {
    e.preventDefault();
    var id = joining.id, name = el.joinName.value.trim().slice(0, 15) || 'Two';
    el.joinBtn.disabled = true;
    el.joinMsg.textContent = 'Joining. .';
    window.DotsNet.join(id, { name: name, color: joining.color }, function (err) {
      el.joinBtn.disabled = false;
      if (err) { el.joinMsg.textContent = err; buzz(null); return; }
      openJoin(id);                             /* now with a seat: into the game */
    });
  }

  /* ---------- playing across the internet ----------
     The server's list of moves is the game. Each browser replays it from
     scratch to get the board, the scores and whose turn it is, and asks for
     the list again every couple of seconds while the other player moves. */

  var poll = { timer: null, fn: null, since: 0 };

  /* Players ask every 2s, easing to every 10s after five quiet minutes.
     Spectators ask every 5s, easing to every 15s after a quiet minute. */
  var PACE = { play: [2000, 10000, 5 * 60 * 1000], watch: [5000, 15000, 60 * 1000] };

  function startPoll(fn, pace) {
    stopPoll();
    pace = pace || PACE.play;
    poll.fn = fn;
    poll.since = poll.since || Date.now();
    var wait = Date.now() - poll.since > pace[2] ? pace[1] : pace[0];
    poll.timer = window.setTimeout(function () {
      poll.timer = null;
      if (!document.hidden) fn();            /* a hidden tab waits for visibilitychange */
    }, wait);
  }

  function stopPoll() {
    if (poll.timer) window.clearTimeout(poll.timer);
    poll.timer = null;
    poll.fn = null;
  }

  function onVisibility() {
    if (!document.hidden && poll.fn && !poll.timer) poll.fn();
    if (!document.hidden && !el.stages.setup.hidden) refreshLobby();
  }

  function netGame(state, net) {
    var i, m, players = [];
    for (i = 0; i < 2; i++) {
      players.push({ name: state.players[i].name, color: state.players[i].color,
                     kind: i === net.side ? 'human' : 'net' });
    }
    var g = makeGame(el.board, state.w, state.h, players);
    for (i = 0; i < state.moves.length; i++) {
      m = edgeToMove(state.moves[i], g.w, g.h);
      g.marker = { x: m.x, y: m.y };          /* ends on the latest line drawn */
      place(g, m.side);
    }
    g.net = { id: net.id, token: net.token, side: net.side, n: state.moves.length, sending: false };
    return g;
  }

  function showNetGame(g) {
    show('game');
    stopDemo();
    el.verdict.hidden = true;
    el.again.hidden = true;
    game = g;
    message('');
    layout(g, true);
    updateScores(g);
    draw(g);
    if (g.done) finish(g);
    else awaitTurn(g);
  }

  /* While it is the other player's turn, keep asking for their move. A
     spectator's turn never comes, so they keep asking until the end. */
  function awaitTurn(g) {
    if (g.done || g.turn === g.net.side) { stopPoll(); poll.since = 0; return; }
    startPoll(function () {
      window.DotsNet.load(g.net.id, function (err, state) {
        if (game !== g) return;               /* quit or replaced meanwhile */
        if (err || state.moves.length <= g.net.n) { awaitTurn(g); return; }
        poll.since = 0;
        showNetGame(netGame(state, g.net));
      });
    }, g.net.side < 0 ? PACE.watch : PACE.play);
  }

  function sendMove(g, key) {
    g.net.sending = true;
    window.DotsNet.move(g.net.id, g.net.token, key, function (err) {
      g.net.sending = false;
      if (game !== g) return;
      if (err) { message(err); resync(g); return; }
      g.net.n++;
      awaitTurn(g);
    });
  }

  /* The server disagreed: take its word for the board. */
  function resync(g) {
    window.DotsNet.load(g.net.id, function (err, state) {
      if (game !== g) return;
      if (err) { message(err); awaitTurn(g); return; }
      showNetGame(netGame(state, g.net));
    });
  }

  /* Leaving a game over the internet: stop asking about it, and drop its link
     from the address bar so a reload starts afresh (the seat is kept). */
  function leaveNet() {
    stopPoll();
    poll.since = 0;
    if (location.hash) history.replaceState(null, '', location.pathname);
  }

  function onHash() {
    var id = window.DotsNet.linkedGame();
    if (id) openJoin(id);
  }

  /* ---------- the lobby ----------
     Listed games, read while the setup screen is showing. Every button just
     opens the game's link, which already knows how to join, watch, resume a
     seat or show a finished board. */

  var lobbyTimer = null;

  function ago(t) {
    var s = Math.max(0, Date.now() / 1000 - t);
    if (s < 60) return 'just now';
    if (s < 3600) return Math.floor(s / 60) + ' min ago';
    if (s < 86400) return Math.floor(s / 3600) + ' h ago';
    return Math.floor(s / 86400) + ' d ago';
  }

  function lobbyName(p) {
    var span = document.createElement('span');
    span.textContent = p.name;
    span.style.color = hex(p.color);
    return span;
  }

  function lobbyRow(kind, e) {
    var li = document.createElement('li'), btn = document.createElement('button');
    var who = document.createElement('span'), when = document.createElement('span');
    var mine = kind !== 'done' && window.DotsNet.seat(e.id);
    who.appendChild(lobbyName(e.players[0]));
    if (e.players[1]) {
      who.appendChild(document.createTextNode(' vs '));
      who.appendChild(lobbyName(e.players[1]));
    }
    who.appendChild(document.createTextNode('  ' + e.w + ' x ' + e.h
      + (kind === 'playing' ? ', ' + e.moves + (e.moves === 1 ? ' move' : ' moves') : '')));
    when.className = 'when';
    when.textContent = ago(e.updated);
    btn.type = 'button';
    btn.className = 'key ghost';
    btn.textContent = mine ? 'Play' : { waiting: 'Join', playing: 'Watch', done: 'See' }[kind];
    btn.addEventListener('click', function () { location.hash = '#g=' + e.id; });
    li.appendChild(btn);
    li.appendChild(who);
    li.appendChild(when);
    return li;
  }

  function showLobby(groups) {
    var kind, list, i, none;
    for (kind in el.lobby) {
      if (!el.lobby.hasOwnProperty(kind)) continue;
      list = el.lobby[kind];
      list.textContent = '';
      for (i = 0; i < (groups[kind] || []).length; i++) list.appendChild(lobbyRow(kind, groups[kind][i]));
      if (!list.children.length) {
        none = document.createElement('li');
        none.className = 'none';
        none.textContent = 'None right now.';
        list.appendChild(none);
      }
    }
  }

  /* Every 15s while the setup screen shows; a hidden tab skips the asking. */
  function refreshLobby() {
    if (lobbyTimer) window.clearTimeout(lobbyTimer);
    lobbyTimer = null;
    if (el.stages.setup.hidden) return;
    if (!document.hidden) {
      window.DotsNet.lobby(function (err, groups) {
        if (el.stages.setup.hidden) return;
        el.lobbyMsg.textContent = err || '';
        if (!err) showLobby(groups);
      });
    }
    lobbyTimer = window.setTimeout(refreshLobby, 15000);
  }

  /* ---------- stages ---------- */

  function show(name) {
    var k;
    for (k in el.stages) if (el.stages.hasOwnProperty(k)) el.stages[k].hidden = k !== name;
  }

  function showTitle() {
    leaveNet();
    show('title');
    game = null;
    startDemo();
  }

  function showSetup() {
    leaveNet();
    show('setup');
    stopDemo();
    el.setupMsg.textContent = '';
    refreshLobby();
    if (window.matchMedia && window.matchMedia('(min-width: 48em)').matches) el.names[0].focus();
  }

  function startGame(w, h) {
    show('game');
    stopDemo();
    el.verdict.hidden = true;
    el.again.hidden = true;
    message('');
    game = makeGame(el.board, w, h, [
      { name: playerName(0), color: colors[0], kind: 'human' },
      { name: playerName(1), color: colors[1], kind: el.kind.value }
    ]);
    layout(game, true);
    updateScores(game);
    draw(game);
  }

  /* ---------- the title screen plays with itself ---------- */

  function startDemo() {
    stopDemo();
    /* TitleScreen ran a 2x2 game in light blue and light magenta. */
    demo = makeGame(el.demo, 2, 2, [{ name: '', color: 9, kind: 'demo' },
                                    { name: '', color: 13, kind: 'demo' }]);
    demo.silent = true;
    layout(demo);
    draw(demo);

    var i = 0, quiet = calm();
    demo.timer = null;

    function step() {
      if (!demo) return;
      if (i >= MINIGAME.length) {
        if (quiet) return;
        demo.timer = window.setTimeout(startDemo, 2200);
        return;
      }
      var code = MINIGAME[i++];
      if (SCANCODE[code]) {
        move(demo, SCANCODE[code], next);
      } else {
        play(demo, SCANSIDE[code - 100]);
        next();
      }
    }

    function next() {
      if (!demo) return;
      if (quiet) { step(); return; }        /* no animation: just settle it */
      demo.timer = window.setTimeout(step, 120);
    }

    /* The Pascal drew the empty grid, then stepped every 120ms; let the board
       be seen for a beat before the first line lands. */
    if (quiet) step(); else demo.timer = window.setTimeout(step, 400);
  }

  function stopDemo() {
    if (demo && demo.timer) window.clearTimeout(demo.timer);
    demo = null;
  }

  /* ---------- wiring ---------- */

  function onResize() {
    if (demo && !el.stages.title.hidden) { layout(demo); draw(demo); }
    if (game && !el.stages.game.hidden) { layout(game, true); draw(game); }
  }

  buildSwatches();
  el.begin.addEventListener('click', showSetup);
  el.setupForm.addEventListener('submit', onSubmit);
  el.kind.addEventListener('change', onKindChange);
  el.joinForm.addEventListener('submit', onJoin);
  el.joinColors.addEventListener('click', function (e) {
    if (e.target.dataset && e.target.dataset.color) pickJoinColor(+e.target.dataset.color);
  });
  document.getElementById('btn-join-own').addEventListener('click', function () {
    joining.id = null;
    showSetup();
  });
  document.addEventListener('visibilitychange', onVisibility);
  window.addEventListener('hashchange', onHash);
  onKindChange();                     /* a reload may restore 'internet' */
  document.getElementById('btn-setup-help').addEventListener('click', openHelp);
  document.getElementById('btn-help').addEventListener('click', openHelp);
  document.getElementById('btn-help-next').addEventListener('click', helpNext);
  document.getElementById('btn-help-next-2').addEventListener('click', helpNext);
  document.getElementById('btn-help-close').addEventListener('click', closeHelp);
  document.getElementById('btn-quit').addEventListener('click', askQuit);
  document.getElementById('btn-yes').addEventListener('click', function () { answerAsk(true); });
  document.getElementById('btn-no').addEventListener('click', function () { answerAsk(false); });
  el.again.addEventListener('click', showSetup);
  el.sound.addEventListener('click', function () {
    audio.on = !audio.on;
    el.sound.textContent = audio.on ? 'Sound on' : 'Sound off';
    el.sound.setAttribute('aria-pressed', audio.on ? 'true' : 'false');
    if (audio.on) beep(880, 30);
  });
  el.board.addEventListener('click', onBoardClick);
  document.addEventListener('keydown', onKeyDown);
  window.addEventListener('resize', onResize);

  if (window.DotsNet.linkedGame()) onHash();
  else showTitle();
}());
