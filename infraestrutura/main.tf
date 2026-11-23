# Define o intervalo de versões aceito para executar esta configuração.
terraform {
  required_version = ">= 1.10, < 2.0"
}

# Recebe TF_VAR_runtime_dir exportada pelo p1.sh e valida o local dos arquivos.
variable "runtime_dir" {
  type        = string
  description = "Pasta absoluta Linux exclusiva das VMs, fora do repositorio."
  validation {
    condition     = startswith(var.runtime_dir, "/home/") && endswith(var.runtime_dir, "/pi-track-field-p1")
    error_message = "Use uma pasta em /home/ terminada em /pi-track-field-p1."
  }
}

# Duas VMs com papéis separados:
# - geradora: executa o simulador em R e grava os lotes CSV;
# - exibicao: hospeda o Data Warehouse (PostgreSQL) e o painel Shiny.
# Recursos, portas e pastas de cada VM ficam em vm.sh, a única fonte desses valores.
locals {
  vms = {
    geradora = { hostname = "pi-track-field" }
    exibicao = { hostname = "pi-track-field-exibicao" }
  }
  # Renderiza o cloud-init de cada VM com a chave pública dedicada ao acesso.
  user_data = {
    for nome, vm in local.vms : nome => templatefile("${path.module}/cloud-init.yaml.tftpl", {
      hostname   = vm.hostname
      public_key = trimspace(file("${var.runtime_dir}/id_ed25519.pub"))
    })
  }
}

# A VM única da versão anterior passa a ser a geradora, sem perder o estado.
moved {
  from = terraform_data.vm
  to   = terraform_data.vm["geradora"]
}

# Provedor embutido: sem plugin externo. O ciclo de criacao chama QEMU local.
# Reiniciar uma VM parada e verificar seu processo cabe ao script p1.sh.
resource "terraform_data" "vm" {
  for_each = local.vms

  input = {
    nome        = each.key
    runtime_dir = var.runtime_dir
    script      = abspath("${path.module}/vm.sh")
  }
  # Mudanças no cloud-init ou no controlador exigem recriar a VM.
  triggers_replace = [sha256(local.user_data[each.key]), filesha256("${path.module}/vm.sh")]

  # Executa o provisionamento local e passa a configuração por variáveis de ambiente.
  provisioner "local-exec" {
    command = "bash \"$VM_SCRIPT\" create"
    environment = {
      VM_SCRIPT    = self.input.script
      VM           = self.input.nome
      P1_RUNTIME   = self.input.runtime_dir
      CLOUD_CONFIG = local.user_data[self.input.nome]
    }
  }

  provisioner "local-exec" {
    # Ao destruir o recurso, desliga a VM sem excluir seus discos.
    when    = destroy
    command = "bash \"$VM_SCRIPT\" stop"
    # O estado da versão com uma VM só não tem "nome": essa VM é a geradora.
    environment = {
      VM_SCRIPT  = self.input.script
      VM         = try(self.input.nome, "geradora")
      P1_RUNTIME = self.input.runtime_dir
    }
  }
}

# Exibe os comandos de acesso e os endereços após a aplicação.
output "ssh_geradora" {
  value = "ssh -i ${var.runtime_dir}/id_ed25519 -p 2222 pi@127.0.0.1"
}
output "ssh_exibicao" {
  value = "ssh -i ${var.runtime_dir}/id_ed25519 -p 2223 pi@127.0.0.1"
}
output "dados_na_geradora" {
  value = "/opt/pi-track-field/dados"
}
output "painel" {
  value = "http://localhost:8080 (VM de exibicao)"
}
