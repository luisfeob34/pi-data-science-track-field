FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive SHINY_HOST=0.0.0.0
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base-core r-cran-shiny r-cran-ggplot2 r-cran-plotly r-cran-dt \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY R/ R/
COPY scripts/ scripts/
COPY painel/app.R painel/app.R
COPY painel/www/ painel/www/
RUN useradd --create-home painel && mkdir -p /app/results/r && chown -R painel:painel /app
USER painel
EXPOSE 8080
CMD ["Rscript", "scripts/iniciar_painel.R", "8080"]
