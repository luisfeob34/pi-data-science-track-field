(() => {
  function iniciar() {
    const filtros = document.getElementById('filtros-painel');
    const pequeno = window.matchMedia('(max-width: 767px)');
    const ajustar = () => { if (filtros) filtros.open = !pequeno.matches; };
    ajustar();
    pequeno.addEventListener('change', ajustar);
    const abas = document.getElementById('aba');
    if (abas) abas.setAttribute('aria-label', 'Seções da análise');
    const reduzido = window.matchMedia('(prefers-reduced-motion: reduce)');
    document.addEventListener('click', (evento) => {
      const alvo = evento.target.closest('button, a.btn, summary, #aba a');
      if (!alvo) return;
      alvo.classList.remove('acionando');
      void alvo.offsetWidth;
      alvo.classList.add('acionando');
      window.setTimeout(() => alvo.classList.remove('acionando'), reduzido.matches ? 0 : 460);
    });
    if (window.jQuery) {
      window.jQuery(document).on('shiny:value', function (evento) {
        if (evento.name !== 'ranking') return;
        const grafico = document.getElementById('ranking');
        if (!grafico) return;
        grafico.classList.remove('entrando');
        void grafico.offsetWidth;
        grafico.classList.add('entrando');
      });
      window.jQuery('a[data-toggle="tab"]').on('shown.bs.tab', function () {
        const painel = document.querySelector('.tab-pane.active');
        if (!painel || !abas) return;
        painel.classList.remove('entrando');
        void painel.offsetWidth;
        painel.classList.add('entrando');
        const limite = abas.getBoundingClientRect().bottom + 16;
        if (painel.getBoundingClientRect().top < limite - 24) {
          const movimento = reduzido.matches ? 'auto' : 'smooth';
          window.scrollTo({ top: window.scrollY + painel.getBoundingClientRect().top - abas.offsetHeight - 28, behavior: movimento });
        }
      });
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', iniciar);
  else iniciar();
})();
