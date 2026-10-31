# 🚀 Grafana Docker Auto Installer

<p align="center">

![Bash](https://img.shields.io/badge/Bash-Script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Compatible-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-OSS-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix_Plugin-Included-D40000?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

</p>

Script desenvolvido para realizar a **implantação totalmente automatizada do Grafana Open Source (OSS) em container Docker** em servidores **Debian** e **Ubuntu**, instalando automaticamente o motor do Docker, gerando a estrutura do Docker Compose, pré-instalando o plugin oficial do Zabbix, integrando redes existentes e liberando o acesso pela porta padrão do Grafana.

O objetivo é simplificar completamente a instalação em containers, eliminando etapas manuais e garantindo que o ambiente esteja isolado, persistente e pronto para uso em poucos minutos.

---

# 📦 Este repositório

Este repositório contém a documentação e o instalador automatizado em Docker para o Grafana Open Source.

| Arquivo | Descrição |
|---------|-----------|
| 📄 `README.md` | Documentação completa do projeto |
| ✅ `docker-grafana.sh` | Instalador automatizado do Grafana OSS via Docker Compose |

---

# ✨ Funcionalidades

- 🚀 Instalação totalmente automatizada em containers Docker.
- 🔍 Detecção automática do sistema operacional e versão.
- 🐧 Compatível com Debian e Ubuntu.
- 🐳 Instalação automática do Docker e Docker Compose Plugin (caso ausentes).
- 📝 Geração automática do arquivo `docker-compose.yml` em `/opt/grafana-docker`.
- 🔌 Pré-instalação automática do plugin oficial do Zabbix (`alexanderzobnin-zabbix-app`).
- 🔗 Detecção e conexão automática à rede Docker do Zabbix (`zabbix-docker_zabbix-net`), se existir.
- 💾 Persistência de dados via volume Docker (`grafana_data`).
- 🩺 Validação automática de saúde (`healthcheck`) da API do Grafana.
- 🔥 Configuração automática do firewall (UFW), caso esteja ativo.
- ⏰ Configuração automática do Timezone (`America/Sao_Paulo`).
- 🎨 Interface amigável com cores e mensagens informativas.

---

# 🖥️ Sistemas suportados

O script identifica automaticamente o sistema operacional.

Atualmente são suportados:

- Debian (11, 12 e 13)
- Ubuntu Server (20.04, 22.04, 24.04 e 26.04)

Caso seja executado em outra distribuição Linux, a instalação será interrompida.

---

# ⚙️ O que o script instala

Além do container oficial do **Grafana OSS**, o script verifica e instala automaticamente (somente se ainda não estiverem presentes no sistema):

- `apt-transport-https`
- `software-properties-common`
- `wget`
- `curl`
- `gnupg2`
- `ca-certificates`
- `lsb-release`
- `docker-ce` / `docker-ce-cli` / `containerd.io`
- `docker-buildx-plugin` / `docker-compose-plugin`

Caso alguma dependência ou o próprio Docker já estejam instalados, a etapa é concluída instantaneamente sem reinstalações desnecessárias.

---

# 🔐 Repositórios e Imagens Oficiais

O script utiliza exclusivamente repositórios e imagens oficiais:

- **Docker Engine:** Repositório oficial `download.docker.com` com chave GPG dedicada em `/etc/apt/keyrings/docker.gpg`.
- **Grafana OSS:** Imagem oficial `grafana/grafana-oss:latest` do Docker Hub.
- **Plugin Zabbix:** Pacote oficial `alexanderzobnin-zabbix-app` baixado automaticamente na inicialização do container.

---

# ⚙️ Como funciona

O processo foi dividido em cinco etapas principais.

---

## 1️⃣ Verificação do ambiente e dependências

Antes de iniciar a instalação, o script verifica:

- permissões de administrador (`root` ou `sudo`);
- integridade do `PATH` administrativo;
- sistema operacional e versão da distribuição;
- presença de pacotes básicos (`wget`, `curl`, `gpg`, `lsb_release`);
- ajuste do fuso horário para `America/Sao_Paulo`.

---

## 2️⃣ Verificação e instalação do Docker

O script verifica se o `docker` e o `docker compose` já estão operacionais no servidor. Caso não estejam, configura a chave GPG e o repositório oficial do Docker e instala todos os pacotes necessários, habilitando o serviço no `systemd`.

---

## 3️⃣ Configuração do ambiente Docker Compose

Nesta etapa são realizadas as seguintes ações:

- criação do diretório `/opt/grafana-docker`;
- verificação automática da existência da rede `zabbix-docker_zabbix-net` para permitir comunicação direta container-a-container com o Zabbix;
- geração do arquivo `/opt/grafana-docker/docker-compose.yml` com variáveis de ambiente, volume persistente e checagem de saúde (`healthcheck`).

---

## 4️⃣ Inicialização do container do Grafana

O script baixa a imagem oficial, cria o volume e inicia o container em segundo plano (`docker compose up -d`). Em seguida, aguarda até que o `healthcheck` interno confirme que a API Web na porta `3000` está respondendo normalmente.

---

## 5️⃣ Configuração do firewall

Caso o **UFW** esteja instalado e ativo (`Status: active`), o script libera automaticamente a porta:

```text
3000/TCP
```

permitindo acesso externo ao painel web do Grafana.

---

# 🔄 Fluxo da instalação

```text
Detectar Sistema
        │
        ▼
Verificar Root e PATH
        │
        ▼
Verificar/Instalar Dependências
        │
        ▼
Verificar/Instalar Docker Compose
        │
        ▼
Detectar Rede do Zabbix (Opcional)
        │
        ▼
Gerar docker-compose.yml
        │
        ▼
Iniciar Container e Plugin Zabbix
        │
        ▼
Validar Healthcheck da API
        │
        ▼
Configurar Firewall (UFW)
        │
        ▼
Exibir Informações de Acesso
```

---

# ▶️ Execução

Conceda permissão ao script:

```bash
chmod +x docker-grafana.sh
```

Execute utilizando **sudo** ou como **root**:

```bash
sudo ./docker-grafana.sh
```

---

# 📋 Etapas exibidas durante a instalação

Durante a execução são exibidas mensagens indicando o progresso:

```text
[ETAPA 1/5]
Verificando dependências essenciais...

[ETAPA 2/5]
Verificando Docker e Docker Compose...

[ETAPA 3/5]
Configurando o ambiente Docker do Grafana em /opt/grafana-docker...

[ETAPA 4/5]
Baixando imagem, instalando plugin do Zabbix e iniciando o Grafana...

[ETAPA 5/5]
Configurando firewall...
```

---

# 🌐 Informações de acesso

Ao finalizar a instalação o script informa automaticamente:

```text
URL:
http://IP_DO_SERVIDOR:3000

Usuário:
admin

Senha:
admin
```

---

# 🔗 Integração com o Zabbix (Container)

Como o script já instala o plugin do Zabbix e conecta o Grafana à rede do Zabbix automaticamente:

1. No menu lateral do Grafana, acesse **Administration** > **Plugins and data** > **Plugins**.
2. Pesquise por **Zabbix**, clique sobre o plugin e clique em **Enable**.
3. Acesse **Connections** > **Data sources** > **Add new data source** e selecione **Zabbix**.
4. No campo **URL**, utilize o endereço interno da rede Docker:
   ```text
   http://zabbix-web:8080/api_jsonrpc.php
   ```
5. Em **Zabbix Connection**, informe o usuário `Admin` e a senha `zabbix`, e clique em **Save & test**.

---

# 🔥 Firewall

Se o **UFW** estiver instalado e ativo, será executado automaticamente:

```bash
ufw allow 3000/tcp comment "Grafana Web UI"
ufw reload
```

Caso o sistema utilize outro firewall, essa configuração deverá ser realizada manualmente.

---

# 📌 Pré-requisitos

- Debian ou Ubuntu
- Bash
- Conexão com a Internet
- Permissão de `root` ou `sudo`
- Acesso ao Docker Hub e aos repositórios oficiais do Docker

---

# 📊 Exemplo de saída

```text
✅ ✅ ✅ Instalação do Grafana concluída com sucesso! ✅ ✅ ✅
========================================================
🌐 ACESSO AO PAINEL DO GRAFANA:
   URL:      [http://172.25.169.173:3000](http://172.25.169.173:3000)
   Usuário:  admin
   Senha:    admin (Você pode alterar pelo menu Profile)
   Plugin:   Zabbix Plugin já pré-instalado!
========================================================
```

---

# 🛠️ Comandos úteis

Verificar o status do container:

```bash
docker compose -f /opt/grafana-docker/docker-compose.yml ps
```

Reiniciar o Grafana:

```bash
docker compose -f /opt/grafana-docker/docker-compose.yml restart
```

Visualizar os logs em tempo real:

```bash
docker compose -f /opt/grafana-docker/docker-compose.yml logs -f
```

Parar o container:

```bash
docker compose -f /opt/grafana-docker/docker-compose.yml stop
```

Iniciar o container:

```bash
docker compose -f /opt/grafana-docker/docker-compose.yml start
```

Atualizar a imagem do Grafana para a versão mais recente:

```bash
cd /opt/grafana-docker && docker compose pull && docker compose up -d
```

---

# ✅ Benefícios

- Instalação rápida em menos de 1 minuto (com Docker já presente)
- Processo totalmente automatizado e isolado em container
- Utiliza apenas imagens e repositórios oficiais
- Pré-instala o plugin do Zabbix e integra as redes automaticamente
- Persistência garantida em volume dedicado (`grafana_data`)
- Compatível com Debian e Ubuntu
- Configuração inteligente do firewall
- Fácil manutenção e atualização sem conflitos de pacotes no sistema host

---

# 🛠️ Tecnologias utilizadas

- Bash
- Docker Engine
- Docker Compose
- Grafana OSS
- Zabbix Plugin (`alexanderzobnin-zabbix-app`)
- APT
- systemd
- UFW
- GnuPG / wget / curl

---

# 🔗 Projetos relacionados

Este script atua em conjunto com o instalador containerizado do Zabbix:

- 🟥 **Zabbix 7.0 LTS Docker Auto Installer (`docker-zabbix-7.sh`)** – Implanta toda a stack do Zabbix 7.0 LTS (MariaDB, Server, Web Apache e Agent) via Docker Compose.

Quando executados no mesmo servidor, o script do Grafana detecta a rede do Zabbix automaticamente e permite a integração direta entre os dois containers.

---

# 📄 Licença

Este projeto está licenciado sob a licença **MIT**.

Você pode utilizar, modificar e distribuir este projeto livremente, desde que mantenha os créditos e o texto da licença.

---

# 👨‍💻 Autor

Desenvolvido para automatizar a implantação do **Grafana Open Source (OSS)** em containers Docker em ambientes Debian e Ubuntu, reduzindo o tempo de configuração, padronizando a integração com o Zabbix e facilitando a administração de servidores Linux.
