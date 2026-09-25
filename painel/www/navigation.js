(() => {
  function iniciar() {
    const filtros = document.getElementById('filtros-painel');
    const pequeno = window.matchMedia('(max-width: 767px)');
    const ajustar = () => { if (filtros) filtros.open = !pequeno.matches; };
    ajustar();
    pequeno.addEventListener('change', ajustar);
    const abas = document.getElementById('aba');
    if (abas) abas.setAttribute('aria-label', 'Seções da análise');
    if (window.jQuery) {
      window.jQuery('a[data-toggle="tab"]').on('shown.bs.tab', function () {
        const painel = document.querySelector('.tab-pane.active');
        if (!painel || !abas) return;
        const limite = abas.getBoundingClientRect().bottom + 16;
        if (painel.getBoundingClientRect().top < limite - 24) {
          const movimento = window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
          window.scrollTo({ top: window.scrollY + painel.getBoundingClientRect().top - abas.offsetHeight - 28, behavior: movimento });
        }
      });
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', iniciar);
  else iniciar();
})();
