// A single component state drives selection, explanation, and the SVG.
// No animation loop, external dependencies, or persistent user settings.
(() => {
    document.querySelectorAll('[data-page-anatomy]').forEach(figure => {
        if (figure.dataset.ready) return;
        const controls = [...figure.querySelectorAll('[data-select-part]')];
        const parts = [...figure.querySelectorAll('[data-part]')];
        const descriptions = [...figure.querySelectorAll('[data-part-description]')];
        const explode = figure.querySelector('[data-explode]');
        const select = key => {
            if (!parts.some(part => part.dataset.part === key)) return;
            figure.dataset.selected = key;
            controls.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.selectPart === key)));
            parts.forEach(part => part.classList.toggle('is-selected', part.dataset.part === key));
            descriptions.forEach(description => { description.hidden = description.dataset.partDescription !== key; });
        };
        controls.forEach(button => {
            button.disabled = false;
            button.addEventListener('click', () => select(button.dataset.selectPart));
        });
        explode.disabled = false;
        explode.addEventListener('change', () => figure.classList.toggle('is-exploded', explode.checked));
        figure.addEventListener('keydown', event => {
            if (event.key !== 'Escape' || !explode.checked) return;
            explode.checked = false;
            figure.classList.remove('is-exploded');
        });
        select('body');
        figure.dataset.ready = 'true';
    });
})();
