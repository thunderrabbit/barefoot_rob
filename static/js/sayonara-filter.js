/* sayonara-filter.js — client-side tag + name filter for the /en/sayonara/ catalog.
 *
 * The whole grid is already in the page; this only shows and hides cells. Tags come
 * from data-tags on each cell (space separated, written by sayonara-item-grid.html
 * from the item_tags front matter). Selected chips OR together; the text box ANDs
 * on top of them and matches tags as well as the item name.
 *
 * The filter bar ships with the `hidden` attribute so a visitor without JS sees the
 * plain grid rather than a control that does nothing. We remove it on init.
 */
(function () {
    'use strict';

    var bar = document.getElementById('sayonara-filter');
    if (!bar) return;

    var cells = Array.prototype.slice.call(document.querySelectorAll('.sayonara-cell'));
    if (!cells.length) return;

    var chips = Array.prototype.slice.call(bar.querySelectorAll('.sayonara-chip'));
    var input = document.getElementById('sayonara-q');
    var clear = document.getElementById('sayonara-clear');
    var count = document.getElementById('sayonara-count');

    var selected = [];

    // Cache each cell's haystack once — tags plus the lowercased title.
    var items = cells.map(function (cell) {
        var tags = (cell.getAttribute('data-tags') || '').split(/\s+/).filter(Boolean);
        return {
            cell: cell,
            tags: tags,
            haystack: tags.join(' ') + ' ' + (cell.getAttribute('data-title') || '')
        };
    });

    function matches(item, query) {
        if (selected.length) {
            var hit = selected.some(function (t) { return item.tags.indexOf(t) !== -1; });
            if (!hit) return false;
        }
        return !query || item.haystack.indexOf(query) !== -1;
    }

    function apply() {
        var query = (input.value || '').trim().toLowerCase();
        var shown = 0;

        items.forEach(function (item) {
            var ok = matches(item, query);
            item.cell.classList.toggle('sayonara-hidden', !ok);
            if (ok) shown++;
        });

        chips.forEach(function (chip) {
            var tag = chip.getAttribute('data-tag');
            var on = tag ? selected.indexOf(tag) !== -1 : selected.length === 0;
            chip.classList.toggle('is-active', on);
            chip.setAttribute('aria-pressed', on ? 'true' : 'false');
        });

        count.textContent = 'Showing ' + shown + ' of ' + items.length;
        clear.hidden = !(selected.length || query);
    }

    chips.forEach(function (chip) {
        chip.addEventListener('click', function () {
            var tag = chip.getAttribute('data-tag');
            if (!tag) {
                selected = [];              // the "all" chip
            } else {
                var at = selected.indexOf(tag);
                if (at === -1) selected.push(tag);
                else selected.splice(at, 1);
            }
            apply();
        });
    });

    input.addEventListener('input', apply);
    clear.addEventListener('click', function () {
        selected = [];
        input.value = '';
        apply();
        input.focus();
    });

    bar.hidden = false;
    apply();
}());
