#!/usr/bin/env bash
# Controla um HDFS local com um NameNode (metadados) e um DataNode (blocos).
set -euo pipefail
# shellcheck source=infraestrutura/bigdata/ambiente.sh
source "$(dirname "${BASH_SOURCE[0]}")/ambiente.sh"
# Prepara as pastas usadas pela configuração e pelos processos Hadoop.
mkdir -p "$HADOOP_CONF_DIR" "$HADOOP_LOG_DIR" "$HADOOP_PID_DIR"
# Instancia academica isolada. Todas as portas escutam apenas em loopback.
case "${1:-status}" in
  iniciar)
    # Exige a instalação e rejeita caracteres que invalidariam os caminhos no XML.
    [[ -x "$HADOOP_HOME/bin/hdfs" ]] || { echo 'Execute instalar.sh primeiro.'; exit 1; }
    [[ "$PI_BIGDATA_HOME" != *'&'* && "$PI_BIGDATA_HOME" != *'<'* ]] || exit 1
    # Usa a configuração de logs fornecida pelo Hadoop se ainda não houver uma local.
    if [[ ! -f "$HADOOP_CONF_DIR/log4j.properties" ]]; then
      cp "$HADOOP_HOME/etc/hadoop/log4j.properties" "$HADOOP_CONF_DIR/log4j.properties"
    fi
    # Define o endereço padrão usado pelos clientes HDFS.
    cat > "$HADOOP_CONF_DIR/core-site.xml" <<EOF
<configuration>
<property><name>fs.defaultFS</name><value>hdfs://127.0.0.1:19000</value></property>
</configuration>
EOF
    # Configura uma réplica por bloco, armazenamento persistente e portas locais.
    cat > "$HADOOP_CONF_DIR/hdfs-site.xml" <<EOF
<configuration>
<property><name>dfs.replication</name><value>1</value></property>
<property><name>dfs.namenode.name.dir</name><value>file://$PI_BIGDATA_HOME/namenode</value></property>
<property><name>dfs.datanode.data.dir</name><value>file://$PI_BIGDATA_HOME/datanode</value></property>
<property><name>dfs.namenode.rpc-address</name><value>127.0.0.1:19000</value></property>
<property><name>dfs.namenode.http-address</name><value>127.0.0.1:19870</value></property>
<property><name>dfs.datanode.address</name><value>127.0.0.1:19866</value></property>
<property><name>dfs.datanode.http.address</name><value>127.0.0.1:19864</value></property>
<property><name>dfs.datanode.ipc.address</name><value>127.0.0.1:19867</value></property>
<property><name>dfs.datanode.hostname</name><value>localhost</value></property>
<property><name>dfs.client.use.datanode.hostname</name><value>true</value></property>
</configuration>
EOF
    # Nunca reformatar um NameNode existente.
    if [[ ! -f "$PI_BIGDATA_HOME/namenode/current/VERSION" ]]; then
      [[ ! -d "$PI_BIGDATA_HOME/namenode" ]] || { echo 'NameNode existente sem VERSION. Inspecione manualmente.'; exit 1; }
      hdfs namenode -format -nonInteractive pi-track-field
    fi
    # Hadoop 3.4 retorna codigo zero ate quando o daemon esta parado.
    for servico in namenode datanode; do
      if ! hdfs --daemon status "$servico" 2>/dev/null | grep -q 'is running as process'; then
        hdfs --daemon start "$servico"
      fi
    done
    # Aguarda o DataNode aparecer e a saída do modo seguro antes de liberar o uso.
    for ((i=0;i<60;i++)); do
      if hdfs dfsadmin -report 2>/dev/null | grep -q 'Live datanodes (1)'; then
        hdfs dfsadmin -safemode wait
        echo 'HDFS pronto: hdfs://127.0.0.1:19000'; exit 0
      fi
      sleep 2
    done
    echo "HDFS indisponivel. Consulte $HADOOP_LOG_DIR"; exit 1
    ;;
  # Encerra primeiro o serviço de blocos e depois o serviço de metadados.
  parar) hdfs --daemon stop datanode; hdfs --daemon stop namenode ;;
  # Sem argumentos, o script mostra o relatório de capacidade e saúde do HDFS.
  status) hdfs dfsadmin -report ;;
  *) echo 'Uso: hdfs.sh iniciar|parar|status'; exit 1 ;;
esac
