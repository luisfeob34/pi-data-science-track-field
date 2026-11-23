#!/usr/bin/env bash
# Controla as VMs QEMU e preserva seus discos entre desligamentos e recriações.
# Uso: VM=geradora|exibicao P1_RUNTIME=... vm.sh create|start|stop|status
set -euo pipefail
# Recebe a pasta pelo roteiro principal; vírgulas interfeririam nas opções do QEMU.
: "${P1_RUNTIME:?Defina P1_RUNTIME pelo roteiro p1.sh}"
base=$(realpath -m "$P1_RUNTIME")
[[ "$base" == /home/*/pi-track-field-p1 && "$base" != *','* ]] || { echo 'Pasta das VMs invalida.' >&2; exit 1; }
# Única fonte dos recursos e portas de cada VM. As portas escutam só no host local.
vm=${VM:-geradora}
case "$vm" in
  # Gera os lotes CSV. Mantém a pasta da versão anterior, com uma VM só.
  geradora) runtime=$base; memoria=1536; porta_ssh=2222; redirecionar='' ;;
  # Hospeda o Data Warehouse e o painel; o painel fica em 127.0.0.1:8080 no host.
  exibicao) runtime=$base/exibicao; memoria=1280; porta_ssh=2223
            redirecionar=',hostfwd=tcp:127.0.0.1:8080-:8080' ;;
  *) echo "VM desconhecida: $vm (use geradora ou exibicao)" >&2; exit 1 ;;
esac
mkdir -p "$base" "$runtime"
chmod 700 "$base" "$runtime"
# Serializa operações para impedir alterações simultâneas na mesma VM.
exec 9>"$runtime/vm.lock"
flock 9
# Confere o PID e o caminho do disco para não confundir outro processo com a VM.
ativo() {
  [[ -f "$runtime/qemu.pid" ]] || return 1
  local pid
  read -r pid < "$runtime/qemu.pid"
  [[ "$pid" =~ ^[0-9]+$ && -r /proc/$pid/cmdline ]] || return 1
  grep -zFxq -- "file=$runtime/disk.qcow2,format=qcow2,if=virtio" "/proc/$pid/cmdline"
}
parar() {
  if ativo; then
    # ACPI permite que o Linux sincronize o disco antes de encerrar.
    python3 - "$runtime/monitor.sock" <<'PY'
import socket, sys
with socket.socket(socket.AF_UNIX) as sock:
    sock.connect(sys.argv[1])
    sock.recv(4096)
    sock.sendall(b'system_powerdown\n')
PY
    # Aguarda até dois minutos pelo encerramento, sem forçar a interrupção.
    for ((i=0; i<120; i++)); do
      if ! ativo; then echo "VM $vm desligada; disco e dados preservados."; return; fi
      sleep 1
    done
    echo "Desligamento da VM $vm ainda pendente. Nao foi forcado para proteger os dados." >&2
    return 1
  fi
}
iniciar() {
  # Reutiliza a VM ativa e exige os discos criados pelo provisionamento.
  if ativo; then echo "VM $vm ja esta em execucao."; return; fi
  [[ -f "$runtime/disk.qcow2" && -f "$runtime/seed.img" ]] || { echo 'Execute criar primeiro.' >&2; exit 1; }
  # Prefere aceleração KVM quando acessível; caso contrário, usa emulação TCG.
  local aceleracao=tcg
  [[ -r /dev/kvm && -w /dev/kvm ]] && aceleracao=kvm
  # Duas CPUs, disco gravável e mídia cloud-init somente leitura.
  # Expõe as portas apenas no host local e registra o console sem abrir janela gráfica.
  # O monitor recebe comandos de controle; fechar o descritor 9 libera o lock ao sair.
  qemu-system-x86_64 -name "pi-track-field-$vm" -accel "$aceleracao" -m "$memoria" -smp 2 \
    -drive "file=$runtime/disk.qcow2,format=qcow2,if=virtio" \
    -drive "file=$runtime/seed.img,format=raw,if=virtio,readonly=on" \
    -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:$porta_ssh-:22$redirecionar" \
    -display none -serial "file:$runtime/console.log" \
    -monitor "unix:$runtime/monitor.sock,server=on,wait=off" \
    -pidfile "$runtime/qemu.pid" -daemonize 9>&-
  echo "VM $vm iniciada ($aceleracao, ${memoria} MiB). SSH: 127.0.0.1:$porta_ssh"
  [[ -z "$redirecionar" ]] || echo 'Painel: http://localhost:8080'
}
case "${1:-}" in
  create)
    # O OpenTofu fornece o conteúdo cloud-init usado na primeira inicialização.
    : "${CLOUD_CONFIG:?cloud-init deve ser fornecido pelo OpenTofu}"
    if [[ -f "$runtime/disk.qcow2" ]]; then
      parar
      # Cada recriacao guarda o disco anterior, inclusive os dados.
      arquivo="$runtime/arquivo-$(date -u +%Y%m%dT%H%M%S)-$$"
      mkdir "$arquivo"
      mv "$runtime/disk.qcow2" "$arquivo/"
      [[ ! -f "$runtime/seed.img" ]] || mv "$runtime/seed.img" "$arquivo/"
      echo "Disco anterior da VM $vm preservado em $arquivo"
    fi
    # As duas VMs usam a mesma imagem Ubuntu verificada, baixada pelo p1.sh.
    [[ -f "$base/base.img" ]] || { echo 'Imagem base ausente; execute p1.sh criar.' >&2; exit 1; }
    # Cria a mídia de inicialização com configuração e identificador de instância.
    printf '%s\n' "$CLOUD_CONFIG" > "$runtime/user-data"
    printf 'instance-id: pi-%s-%s\nlocal-hostname: pi-track-field-%s\n' "$vm" "$(date +%s)-$$" "$vm" > "$runtime/meta-data"
    cloud-localds "$runtime/seed.img" "$runtime/user-data" "$runtime/meta-data"
    # O disco de 12 GiB armazena alterações sobre a imagem base, da qual depende.
    qemu-img create -f qcow2 -F qcow2 -b "$base/base.img" "$runtime/disk.qcow2" 12G
    # Uma VM recriada terá outra chave SSH; remove o registro da instância anterior.
    if [[ -f "$base/known_hosts" ]]; then
      ssh-keygen -R "[127.0.0.1]:$porta_ssh" -f "$base/known_hosts" >/dev/null 2>&1 || true
    fi
    iniciar
    ;;
  # Operações de rotina preservam os discos e os dados da VM.
  start) iniciar ;;
  stop) parar ;;
  status) if ativo; then echo "VM $vm em execucao"; else echo "VM $vm desligada"; exit 1; fi ;;
  *) echo 'Uso: VM=geradora|exibicao vm.sh create|start|stop|status' >&2; exit 1 ;;
esac
