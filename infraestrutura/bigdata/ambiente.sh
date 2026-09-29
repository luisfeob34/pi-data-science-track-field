#!/usr/bin/env bash
# Carregado pelos scripts; nao altera o perfil do usuario.
export PI_BIGDATA_HOME="${PI_BIGDATA_HOME:-$HOME/.local/share/pi-track-field-bigdata}"
export SPARK_HOME="$PI_BIGDATA_HOME/spark-3.5.8-bin-hadoop3"
export HADOOP_HOME="$PI_BIGDATA_HOME/hadoop-3.4.2"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export SPARK_LOCAL_IP=127.0.0.1
export HADOOP_CONF_DIR="$PI_BIGDATA_HOME/conf"
export HADOOP_LOG_DIR="$PI_BIGDATA_HOME/logs"
export HADOOP_PID_DIR="$PI_BIGDATA_HOME/pids"
export HADOOP_HEAPSIZE_MAX=256
export PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"
