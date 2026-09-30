#!/usr/bin/env bash
# Carregado pelos scripts; nao altera o perfil do usuario.
# Permite escolher a pasta de instalação sem modificar os scripts consumidores.
export PI_BIGDATA_HOME="${PI_BIGDATA_HOME:-$HOME/.local/share/pi-track-field-bigdata}"
# Os caminhos devem corresponder às versões baixadas pelo instalar.sh.
export SPARK_HOME="$PI_BIGDATA_HOME/spark-3.5.8-bin-hadoop3"
export HADOOP_HOME="$PI_BIGDATA_HOME/hadoop-3.4.2"
# Preserva uma instalação Java informada pelo usuário ou usa o OpenJDK 17 padrão.
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
# Usa loopback para a comunicação local do Spark.
export SPARK_LOCAL_IP=127.0.0.1
# Separa configurações, logs e identificadores dos processos dos arquivos instalados.
export HADOOP_CONF_DIR="$PI_BIGDATA_HOME/conf"
export HADOOP_LOG_DIR="$PI_BIGDATA_HOME/logs"
export HADOOP_PID_DIR="$PI_BIGDATA_HOME/pids"
# Limita o heap Java do Hadoop a 256 MiB para o ambiente acadêmico local.
export HADOOP_HEAPSIZE_MAX=256
# Disponibiliza os comandos Spark e Hadoop no ambiente que carregou este arquivo.
export PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"
