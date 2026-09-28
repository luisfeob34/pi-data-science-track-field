#!/usr/bin/env bash
set -euo pipefail
: "${P1_RUNTIME:?Defina P1_RUNTIME pelo roteiro p1.sh}"
runtime=$(realpath -m "$P1_RUNTIME")
[[ "$runtime" == /home/*/pi-track-field-p1 && "$runtime" != *','* ]] || { echo 'Pasta da VM invalida.' >&2; exit 1; }
mkdir -p "$runtime"
chmod 700 "$runtime"
exec 9>"$runtime/vm.lock"
flock 9
ativo() {
  [[ -f "$runtime/qemu.pid" ]] || return 1
  local pid
  read -r pid < "$runtime/qemu.pid"
  [[ "$pid" =~ ^[0-9]+$ && -r /proc/$pid/cmdline ]] || return 1
  grep -zFq -- "$runtime/disk.qcow2" "/proc/$pid/cmdline"
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
    for ((i=0; i<120; i++)); do
      if ! ativo; then echo 'VM desligada; disco e dados preservados.'; return; fi
      sleep 1
    done
    echo 'Desligamento ainda pendente. Nao foi forcado para proteger os dados.' >&2
    return 1
  fi
}
iniciar() {
  if ativo; then echo 'VM ja esta em execucao.'; return; fi
  [[ -f "$runtime/disk.qcow2" && -f "$runtime/seed.img" ]] || { echo 'Execute criar primeiro.' >&2; exit 1; }
  local aceleracao=tcg
  [[ -r /dev/kvm && -w /dev/kvm ]] && aceleracao=kvm
  qemu-system-x86_64 -name pi-track-field-p1 -accel "$aceleracao" -m 1536 -smp 2 \
    -drive "file=$runtime/disk.qcow2,format=qcow2,if=virtio" \
    -drive "file=$runtime/seed.img,format=raw,if=virtio,readonly=on" \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
    -display none -serial "file:$runtime/console.log" \
    -monitor "unix:$runtime/monitor.sock,server=on,wait=off" \
    -pidfile "$runtime/qemu.pid" -daemonize 9>&-
  echo "VM iniciada ($aceleracao). SSH: 127.0.0.1:2222"
}
case "${1:-}" in
  create)
    : "${CLOUD_CONFIG:?cloud-init deve ser fornecido pelo OpenTofu}"
    if [[ -f "$runtime/disk.qcow2" ]]; then
      parar
      # Cada recriacao guarda o disco anterior, inclusive os CSVs.
      arquivo="$runtime/arquivo-$(date -u +%Y%m%dT%H%M%S)-$$"
      mkdir "$arquivo"
      mv "$runtime/disk.qcow2" "$arquivo/"
      [[ ! -f "$runtime/seed.img" ]] || mv "$runtime/seed.img" "$arquivo/"
      echo "Disco anterior preservado em $arquivo"
    fi
    [[ -f "$runtime/base.img" ]] || { echo 'Imagem base ausente; execute p1.sh criar.' >&2; exit 1; }
    printf '%s\n' "$CLOUD_CONFIG" > "$runtime/user-data"
    printf 'instance-id: pi-p1-%s\nlocal-hostname: pi-track-field\n' "$(date +%s)-$$" > "$runtime/meta-data"
    cloud-localds "$runtime/seed.img" "$runtime/user-data" "$runtime/meta-data"
    qemu-img create -f qcow2 -F qcow2 -b "$runtime/base.img" "$runtime/disk.qcow2" 12G
    if [[ -f "$runtime/known_hosts" ]]; then
      ssh-keygen -R '[127.0.0.1]:2222' -f "$runtime/known_hosts" >/dev/null
    fi
    iniciar
    ;;
  start) iniciar ;;
  stop) parar ;;
  status) if ativo; then echo 'VM em execucao'; else echo 'VM desligada'; exit 1; fi ;;
  *) echo 'Uso: vm.sh create|start|stop|status' >&2; exit 1 ;;
esac
