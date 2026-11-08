FROM rocker/r-ver:4.4.1

WORKDIR /app

COPY install_packages.R .
RUN Rscript install_packages.R

COPY main.R .

# data gets mounted here when running the container
ENV DATA_DIR=/app/data

CMD ["Rscript", "main.R"]
