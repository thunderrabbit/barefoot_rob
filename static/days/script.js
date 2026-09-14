(function () {
  "use strict";

  var MS = 86400000;
  var HORIZON = 20000;
  var WANTED = 15;
  var PER_KIND = 3;
  var FIRST_YEAR = 1900;

  var MONTHS = ['January','February','March','April','May','June',
                'July','August','September','October','November','December'];
  var MONTHS_SHORT = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  var DOW = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  var el = {
    crumbs: document.getElementById('crumbs'),
    stepYear: document.getElementById('step-year'),
    stepMonth: document.getElementById('step-month'),
    stepDay: document.getElementById('step-day'),
    years: document.getElementById('years'),
    months: document.getElementById('months'),
    cal: document.getElementById('cal'),
    yearPrompt: document.getElementById('yearPrompt'),
    monthPrompt: document.getElementById('monthPrompt'),
    dayPrompt: document.getElementById('dayPrompt'),
    note: document.getElementById('note'),
    share: document.getElementById('share'),
    reset: document.getElementById('reset'),
    count: document.getElementById('count'),
    bignum: document.getElementById('bignum'),
    todayline: document.getElementById('todayline'),
    ageline: document.getElementById('ageline'),
    kinds: document.getElementById('kinds'),
    list: document.getElementById('list')
  };

  /* ---------- dates ---------- */

  function utc(y, m, d) { return new Date(Date.UTC(y, m, d)); }

  function today() {
    var n = new Date();
    return utc(n.getFullYear(), n.getMonth(), n.getDate());
  }

  function addDays(d, n) { return new Date(d.getTime() + n * MS); }
  function diffDays(a, b) { return Math.round((a - b) / MS); }
  function daysInMonth(y, m) { return new Date(Date.UTC(y, m + 1, 0)).getUTCDate(); }
  function pad(n) { return n < 10 ? '0' + n : String(n); }

  var fmtLong = new Intl.DateTimeFormat(undefined, {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC'
  });
  var fmtRow = new Intl.DateTimeFormat(undefined, {
    weekday: 'short', day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC'
  });

  function comma(n) { return n.toLocaleString(); }

  function ageParts(birth, on) {
    var y = on.getUTCFullYear() - birth.getUTCFullYear();
    var m = on.getUTCMonth() - birth.getUTCMonth();
    var d = on.getUTCDate() - birth.getUTCDate();
    if (d < 0) { m -= 1; d += daysInMonth(on.getUTCFullYear(), on.getUTCMonth() - 1); }
    if (m < 0) { m += 12; y -= 1; }
    return { y: y, m: m, d: d };
  }

  function ageText(p) {
    var bits = [];
    if (p.y) bits.push(p.y + (p.y === 1 ? ' year' : ' years'));
    if (p.m) bits.push(p.m + (p.m === 1 ? ' month' : ' months'));
    if (p.d || !bits.length) bits.push(p.d + (p.d === 1 ? ' day' : ' days'));
    return bits.join(', ');
  }

  function awayText(n) {
    if (n === 1) return 'tomorrow';
    if (n < 7) return 'in ' + n + ' days';
    var w = Math.round(n / 7), mo = Math.round(n / 30.44);
    if (n < 60) return 'in ' + n + ' days · about ' + w + (w === 1 ? ' week' : ' weeks');
    if (n < 730) return 'in ' + comma(n) + ' days · about ' + mo + ' months';
    return 'in ' + comma(n) + ' days · about ' + (n / 365.25).toFixed(1) + ' years';
  }

  /* ---------- number properties ---------- */

  function isPrime(n) {
    if (n < 2) return false;
    if (n % 2 === 0) return n === 2;
    if (n % 3 === 0) return n === 3;
    for (var i = 5; i * i <= n; i += 6) {
      if (n % i === 0 || n % (i + 2) === 0) return false;
    }
    return true;
  }

  function isPalindrome(n) {
    var s = String(n);
    return s.length > 2 && s === s.split('').reverse().join('');
  }

  function isRepdigit(n) {
    var s = String(n);
    return s.length > 2 && /^(\d)\1+$/.test(s);
  }

  function isRun(n) {
    var s = String(n);
    if (s.length < 4) return false;
    var up = true, down = true;
    for (var i = 1; i < s.length; i++) {
      if (+s[i] !== +s[i - 1] + 1) up = false;
      if (+s[i] !== +s[i - 1] - 1) down = false;
    }
    return up || down;
  }

  function kindsOf(n) {
    var k = [];
    if (n % 1000 === 0) k.push('thousand');
    if (isPalindrome(n)) k.push('palindrome');
    if (isRepdigit(n)) k.push('repdigit');
    if (isRun(n)) k.push('run');
    if (isPrime(n)) k.push('prime');
    return k;
  }

  var WHY = {
    prime: function (n) { return comma(n) + ' divides by nothing but itself and 1.'; },
    palindrome: function () { return 'Reads the same forwards and backwards.'; },
    thousand: function (n) { return 'A clean ' + comma(n / 1000) + ' thousand days.'; },
    repdigit: function () { return 'Every digit the same.'; },
    run: function () { return 'Digits marching in order.'; }
  };

  var LABEL = {
    prime: 'prime', palindrome: 'palindrome', thousand: 'round thousand',
    repdigit: 'all one digit', run: 'digits in a run'
  };

  /* ---------- picker ---------- */

  var now = today();
  var CUR_Y = now.getUTCFullYear(), CUR_M = now.getUTCMonth(), CUR_D = now.getUTCDate();
  var sel = { y: null, m: null, d: null };
  var birth = null;
  var person = null;

  function showStep(which) {
    el.stepYear.hidden = which !== 'year';
    el.stepMonth.hidden = which !== 'month';
    el.stepDay.hidden = which !== 'day';
    el.crumbs.hidden = (which === 'year' && sel.y === null);
    drawCrumbs(which);
  }

  function drawCrumbs(which) {
    el.crumbs.innerHTML = '';
    if (sel.y === null) return;

    function crumb(text, go) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = text;
      b.addEventListener('click', go);
      el.crumbs.appendChild(b);
    }
    function sep() {
      var s = document.createElement('span');
      s.textContent = '·';
      el.crumbs.appendChild(s);
    }

    crumb(String(sel.y), function () { showStep('year'); drawYears(); });
    if (sel.m !== null) {
      sep();
      crumb(MONTHS[sel.m], function () { showStep('month'); drawMonths(); });
    }
    if (sel.d !== null && which === 'done') {
      sep();
      crumb(String(sel.d), function () { showStep('day'); drawDays(); });
    }
  }

  function cell(text, opts) {
    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'pick' + (opts && opts.on ? ' on' : '');
    b.textContent = text;
    if (opts && opts.disabled) b.disabled = true;
    if (opts && opts.onClick) b.addEventListener('click', opts.onClick);
    return b;
  }

  function drawYears() {
    el.years.innerHTML = '';
    for (var y = CUR_Y; y >= FIRST_YEAR; y--) {
      (function (year) {
        el.years.appendChild(cell(String(year), {
          on: sel.y === year,
          onClick: function () {
            if (sel.y !== year) { sel.m = null; sel.d = null; }
            sel.y = year;
            showStep('month');
            drawMonths();
          }
        }));
      })(y);
    }
    // open somewhere plausible for a birth year rather than at today
    var target = el.years.children[45];
    if (target) el.years.scrollTop = target.offsetTop - el.years.children[0].offsetTop;
  }

  function drawMonths() {
    el.monthPrompt.textContent = 'Which month of ' + sel.y + '?';
    el.months.innerHTML = '';
    MONTHS_SHORT.forEach(function (name, i) {
      var future = sel.y === CUR_Y && i > CUR_M;
      el.months.appendChild(cell(name, {
        on: sel.m === i,
        disabled: future,
        onClick: function () {
          if (sel.m !== i) sel.d = null;
          sel.m = i;
          showStep('day');
          drawDays();
        }
      }));
    });
  }

  function drawDays() {
    el.dayPrompt.textContent = 'Which day of ' + MONTHS[sel.m] + ' ' + sel.y + '?';
    el.cal.innerHTML = '';

    DOW.forEach(function (d) {
      var h = document.createElement('div');
      h.className = 'dow';
      h.textContent = d;
      el.cal.appendChild(h);
    });

    var lead = utc(sel.y, sel.m, 1).getUTCDay();
    for (var i = 0; i < lead; i++) {
      var blank = document.createElement('div');
      blank.className = 'blank';
      el.cal.appendChild(blank);
    }

    var total = daysInMonth(sel.y, sel.m);
    for (var d = 1; d <= total; d++) {
      (function (day) {
        var future = sel.y === CUR_Y && sel.m === CUR_M && day > CUR_D;
        el.cal.appendChild(cell(String(day), {
          on: sel.d === day,
          disabled: future,
          onClick: function () { sel.d = day; commit(); }
        }));
      })(d);
    }
  }

  /* ---------- results ---------- */

  function commit() {
    birth = utc(sel.y, sel.m, sel.d);
    el.stepYear.hidden = el.stepMonth.hidden = el.stepDay.hidden = true;
    el.crumbs.hidden = false;
    drawCrumbs('done');

    var n = diffDays(now, birth);

    el.note.textContent = (person ? person + ' was born ' : 'Born ') + fmtLong.format(birth) + '.';
    el.share.hidden = false;
    el.reset.hidden = false;
    el.count.className = 'count on';
    el.kinds.className = 'kinds on';
    el.list.className = 'list on';

    showNumber(n);
    el.todayline.innerHTML = 'Today is <b>' + fmtLong.format(now) + '</b>.';
    el.ageline.textContent = (person ? person + ' has been alive ' : 'That is ')
      + ageText(ageParts(birth, now)) + (person ? '.' : ' of being alive.');
    render(n);

    document.title = (person ? person + ' — ' : '') + comma(n) + ' days · Daymark';

    try {
      history.replaceState(null, '', location.pathname + query());
    } catch (e) { /* file:// */ }
  }

  function isoSel() { return sel.y + '-' + pad(sel.m + 1) + '-' + pad(sel.d); }

  function query() {
    return '?born=' + isoSel() + (person ? '&name=' + encodeURIComponent(person) : '');
  }

  function greet() {
    el.yearPrompt.textContent = person
      ? 'Which year was ' + person + ' born?'
      : 'Which year were you born?';
  }

  function showNumber(n) {
    var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce || n < 40) { el.bignum.textContent = comma(n); return; }
    var from = n - 30, start = null;
    function step(ts) {
      if (start === null) start = ts;
      var p = Math.min((ts - start) / 700, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.bignum.textContent = comma(Math.round(from + (n - from) * eased));
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  function selectedKinds() {
    var out = {};
    Array.prototype.forEach.call(el.kinds.querySelectorAll('input'), function (i) {
      out[i.value] = i.checked;
    });
    return out;
  }

  function render(current) {
    var want = selectedKinds();
    var quota = {}, live = 0;
    Object.keys(want).forEach(function (k) { if (want[k]) { quota[k] = PER_KIND; live++; } });

    // Primes turn up every ten days or so at this scale, so a plain chronological
    // scan would be nothing but primes. Take the next few of each kind instead.
    var byNumber = {};
    for (var n = current + 1; n <= current + HORIZON && live > 0; n++) {
      var hit = kindsOf(n).filter(function (x) { return quota[x] > 0; });
      if (!hit.length) continue;
      hit.forEach(function (x) { quota[x] -= 1; if (quota[x] === 0) live -= 1; });
      byNumber[n] = kindsOf(n).filter(function (x) { return want[x]; });
    }

    var found = Object.keys(byNumber).map(Number)
      .sort(function (a, b) { return a - b; })
      .slice(0, WANTED);

    el.list.innerHTML = '';

    if (!found.length) {
      var none = document.createElement('li');
      none.className = 'empty';
      none.textContent = 'Nothing selected. Switch a milestone type back on to see what is coming.';
      el.list.appendChild(none);
      return;
    }

    found.forEach(function (num) {
      var kinds = byNumber[num];
      var when = addDays(birth, num);
      var li = document.createElement('li');
      li.className = 'row';
      li.style.setProperty('--k', 'var(--' + kinds[0] + ')');

      var a = document.createElement('div');
      a.className = 'num';
      a.textContent = comma(num);

      var b = document.createElement('div');
      b.className = 'when';
      b.textContent = fmtRow.format(when);

      var c = document.createElement('div');
      c.className = 'away';
      c.textContent = awayText(num - current);

      var tags = document.createElement('div');
      tags.className = 'tags';
      kinds.forEach(function (k) {
        var t = document.createElement('span');
        t.className = 'tag ' + k;
        t.textContent = LABEL[k];
        tags.appendChild(t);
      });

      var why = document.createElement('div');
      why.className = 'why';
      why.textContent = kinds.map(function (k) { return WHY[k](num); }).join(' ');

      li.appendChild(a); li.appendChild(b); li.appendChild(c);
      li.appendChild(tags); li.appendChild(why);
      el.list.appendChild(li);
    });
  }

  /* ---------- wiring ---------- */

  el.kinds.addEventListener('change', function () {
    if (birth) render(diffDays(now, birth));
  });

  el.share.addEventListener('click', function () {
    var link = location.origin + location.pathname + query();
    function done(msg) { el.note.textContent = msg; }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(link).then(
        function () { done('Link copied. It reopens on this day count.'); },
        function () { done(link); }
      );
    } else { done(link); }
  });

  el.reset.addEventListener('click', function () {
    sel = { y: null, m: null, d: null };
    birth = null;
    person = null;
    greet();
    document.title = "Daymark — the day you're on, and the ones worth marking";
    el.note.textContent = '';
    el.share.hidden = true;
    el.reset.hidden = true;
    el.count.className = 'count';
    el.kinds.className = 'kinds';
    el.list.className = 'list';
    el.list.innerHTML = '';
    el.bignum.textContent = '0';
    el.todayline.textContent = '';
    el.ageline.textContent = '';
    Array.prototype.forEach.call(el.kinds.querySelectorAll('input'), function (i) {
      i.checked = true;
    });
    showStep('year');
    drawYears();
    try { history.replaceState(null, '', location.pathname); } catch (e) { /* file:// */ }
    window.scrollTo(0, 0);
  });

  /* ---------- incoming query string ---------- */

  // ?born=1970-02-06  (also dob=, birth=, b=; also 19700206 and 1970/2/6)
  // &name=Rob         (also who=, for=)
  function param() {
    var out = {}, q = location.search.replace(/^\?/, '');
    if (!q) return out;
    q.split('&').forEach(function (pair) {
      if (!pair) return;
      var i = pair.indexOf('='), k, v;
      k = (i < 0 ? pair : pair.slice(0, i)).toLowerCase();
      v = i < 0 ? '' : pair.slice(i + 1).replace(/\+/g, ' ');
      try { v = decodeURIComponent(v); } catch (e) { /* leave raw */ }
      if (!(k in out)) out[k] = v;
    });
    return out;
  }

  function readDate(raw) {
    var m = /^(\d{4})\D?(\d{1,2})\D?(\d{1,2})$/.exec((raw || '').trim());
    if (!m) return null;
    var y = +m[1], mo = +m[2] - 1, d = +m[3];
    if (y < FIRST_YEAR || y > CUR_Y || mo < 0 || mo > 11) return null;
    if (d < 1 || d > daysInMonth(y, mo)) return null;
    if (utc(y, mo, d) > now) return null;
    return { y: y, m: mo, d: d };
  }

  function readName(raw) {
    if (!raw) return null;
    var n = raw.replace(/[\u0000-\u001F<>]/g, '').trim().slice(0, 40);
    return n || null;
  }

  var q = param();
  person = readName(q.name || q.who || q['for']);
  greet();

  var incoming = readDate(q.born || q.dob || q.birth || q.b);
  if (incoming) {
    sel = incoming;
    drawYears(); drawMonths(); drawDays();
    commit();
  } else {
    showStep('year');
    drawYears();
  }
})();
