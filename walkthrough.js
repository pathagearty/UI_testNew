(() => {
  'use strict';
  const STORAGE_KEY = 'clearway-foundry-harness-walkthrough-v1';
  const boxes = [...document.querySelectorAll('[data-check-key]')];
  const progress = document.getElementById('walkProgress');
  const progressLabel = document.getElementById('progressLabel');
  const progressCount = document.getElementById('progressCount');
  const resetButton = document.getElementById('resetWalk');
  const printButton = document.getElementById('printWalk');
  const search = document.getElementById('walkSearch');
  const noResults = document.getElementById('noResults');

  function loadState() {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}'); }
    catch { return {}; }
  }
  function saveState() {
    const state = {};
    boxes.forEach(box => { if (box.checked) state[box.dataset.checkKey] = true; });
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }
  function updateProgress() {
    const complete = boxes.filter(box => box.checked).length;
    const percent = boxes.length ? Math.round((complete / boxes.length) * 100) : 0;
    progress.style.width = `${percent}%`;
    progressLabel.textContent = `${percent}% complete`;
    progressCount.textContent = `${complete} / ${boxes.length} controls`;
  }
  const state = loadState();
  boxes.forEach(box => {
    box.checked = Boolean(state[box.dataset.checkKey]);
    box.addEventListener('change', () => { saveState(); updateProgress(); });
  });
  updateProgress();

  resetButton?.addEventListener('click', () => {
    if (!window.confirm('Reset every saved walkthrough checkbox on this browser?')) return;
    boxes.forEach(box => { box.checked = false; });
    localStorage.removeItem(STORAGE_KEY);
    updateProgress();
  });
  printButton?.addEventListener('click', () => window.print());

  search?.addEventListener('input', () => {
    const query = search.value.trim().toLowerCase();
    const headings = [...document.querySelectorAll('#walkContent h2')];
    let visible = 0;
    headings.forEach((heading, index) => {
      const nextHeading = headings[index + 1];
      const sectionNodes = [];
      let node = heading;
      while (node && node !== nextHeading) {
        sectionNodes.push(node);
        node = node.nextElementSibling;
      }
      const text = sectionNodes.map(item => item.textContent).join(' ').toLowerCase();
      const show = !query || text.includes(query);
      sectionNodes.forEach(item => item.classList.toggle('match-hide', !show));
      if (show) visible += 1;
    });
    // Keep the introductory content visible when no query is active.
    const firstH2 = headings[0];
    let intro = document.querySelector('#walkContent > :first-child');
    while (intro && intro !== firstH2) {
      intro.classList.toggle('match-hide', Boolean(query));
      intro = intro.nextElementSibling;
    }
    if (noResults) noResults.style.display = query && visible === 0 ? 'block' : 'none';
  });
})();
