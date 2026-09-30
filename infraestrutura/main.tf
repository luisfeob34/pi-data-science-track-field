# Define o intervalo de versões aceito para executar esta configuração.
terraform {
  required_version = ">= 1.10, < 2.0"
}

# Recebe TF_VAR_runtime_dir exportada pelo p1.sh e valida o local dos arquivos.
variable "runtime_dir" {
  type        = string
  description = "Pasta absoluta Linux exclusiva da VM, fora do repositorio."
  validation {
    condition     = startswith(var.runtime_dir, "/home/") && endswith(var.runtime_dir, "/pi-track-field-p1")
    error_message = "Use uma pasta em /home/ terminada em /pi-track-field-p1."
  }
}

# Renderiza o cloud-init com a chave pública dedicada ao acesso à VM.
locals {
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    public_key = trimspace(file("${var.runtime_dir}/id_ed25519.pub"))
  })
}

# Provedor embutido: sem plugin externo. O ciclo de criacao chama QEMU local.
# Reiniciar uma VM parada e verificar seu processo cabe ao script p1.sh.
resource "terraform_data" "vm" {
  input = {
    runtime_dir = var.runtime_dir
    script      = abspath("${path.module}/vm.sh")
  }
  # Mudanças no cloud-init ou no controlador exigem recriar o recurso.
  triggers_replace = [sha256(local.user_data), filesha256("${path.module}/vm.sh")]

  # Executa o provisionamento local e passa a configuração por variáveis de ambiente.
  provisioner "local-exec" {
    command = "bash \"$VM_SCRIPT\" create"
    environment = {
      VM_SCRIPT    = self.input.script
      P1_RUNTIME   = self.input.runtime_dir
      CLOUD_CONFIG = local.user_data
    }
  }

  provisioner "local-exec" {
    # Ao destruir o recurso, desliga a VM sem excluir seus discos.
    when    = destroy
    command = "bash \"$VM_SCRIPT\" stop"
    environment = {
      VM_SCRIPT  = self.input.script
      P1_RUNTIME = self.input.runtime_dir
    }
  }
}

# Exibe o comando de acesso e o caminho dos dados após a aplicação.
output "ssh" {
  value = "ssh -i ${var.runtime_dir}/id_ed25519 -p 2222 pi@127.0.0.1"
}
output "dados_na_vm" {
  value = "/opt/pi-track-field/dados"
}
