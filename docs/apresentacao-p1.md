## 1. Problema e objetivo — 30 segundos

“Nosso projeto estuda vendas simuladas de artigos esportivos. Nesta entrega,
automatizamos uma máquina Linux e a geração dos dados que serão analisados pelo
projeto. Os dados são sintéticos; não representam informações reais da empresa.”

## 2. Infraestrutura como código — 1 minuto

Abra `infraestrutura/main.tf` e `cloud-init.yaml.tftpl`.

“O OpenTofu aciona o QEMU para criar uma VM Ubuntu. O cloud-init cria o usuário
pi e configura sua chave SSH no primeiro boot. O WSL é o host de administração;
o simulador roda em outra máquina, a VM QEMU.”

Mostre no log o plano e `Apply complete`. Explique que o uso de `terraform_data`
com `local-exec` é explícito: o script implementa a criação e o desligamento;
não há monitoramento contínuo do processo pelo OpenTofu.

## 3. Acesso e configuração — 1 minuto

Execute `bash infraestrutura/p1.sh validar` para mostrar hostname, kernel e
cloud-init. Abra `infraestrutura/ansible/playbook.yml`.

“O Ansible conecta via SSH, instala o R e cria as pastas. Ao aplicar novamente,
a configuração já está correta, por isso esperamos changed=0.”

Mostre a segunda aplicação no log. Se ela tiver alterações ou erros, não declare
idempotência: corrija e rode a demonstração novamente.

## 4. Simulador e persistência — 1 minuto

Execute `bash infraestrutura/p1.sh simular` e depois `validar`.

“O código é transferido por SCP. Cada execução gera mil registros em um novo CSV
dentro da VM. Temos identificador, data, produto, quantidade e valores, além das
dimensões para análise. A combinação de execução e pedido identifica o registro
entre lotes. Repetir o comando mantém os arquivos anteriores.”

Entre com `bash infraestrutura/p1.sh ssh` e mostre:

```bash
find /opt/pi-track-field/dados -name vendas.csv
head -n 3 /opt/pi-track-field/dados/exec-*/vendas.csv
```

## 5. Reprodução — 30 segundos

Mostre o README e o comando `bash infraestrutura/p1.sh demonstrar`.
Explique onde ficam o código, os logs e os CSVs. Finalize com os próximos passos
do PI somente se forem exigidos pelo professor; o painel e as análises em R
já existentes são uma parte distinta da infraestrutura desta entrega.

Uso: bash infraestrutura/p1.sh criar|configurar|transferir|simular|validar|demonstrar|baixar|ssh|iniciar|parar|status
## Executar em um computador novo

No computador novo, você precisa preparar o ambiente primeiro.

1. Tenha **Ubuntu/WSL instalado** e abra o terminal do Ubuntu.
# Instalar o Git
sudo apt update
sudo apt install -y git

2. Clone o repositório e entre na pasta:

   ```bash
   git clone URL_DO_SEU_REPOSITORIO
   cd PI-Data-Science-Track-Field
   ```

   Substitua `URL_DO_SEU_REPOSITORIO` pelo endereço do GitHub.

3. Instale as ferramentas — somente na primeira vez:

   ```bash
   bash infraestrutura/preparar-host.sh
   ```

4. Execute a demonstração:

   ```bash
   bash infraestrutura/p1.sh demonstrar
   ```

5. Baixe os Arquivos para a máquina local

    ```bash
   bash infraestrutura/p1.sh baixar
   ```

6. Encerre a VM

 ```bash
   bash infraestrutura/p1.sh parar
   ```