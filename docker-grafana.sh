#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação Automatizada em Docker - Grafana (Open Source)
# Compatibilidade: Ubuntu Server (20.04, 22.04, 24.04, 26.04) e Debian (11, 12, 13)
# ==============================================================================

set -e

# Cores para mensagens
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === VERIFICAÇÃO DE ROOT ===
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${RED}❌ ERRO: Este script deve ser executado como root ou com sudo.${NC}" >&2
    exit 1
fi

# === GARANTINDO O PATH CORRETO PARA O ROOT ===
if [[ ":$PATH:" != *":/usr/sbin:"* || ":$PATH:" != *":/sbin:"* || ":$PATH:" != *":/usr/local/sbin:"* ]]; then
    echo -e "${YELLOW}⚠️ PATH do root incompleto. Adicionando diretórios administrativos ao PATH...${NC}"
    export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

export DEBIAN_FRONTEND=noninteractive

# Função para detectar o sistema
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            echo "debian"
        elif [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    else
        echo "unknown"
    fi
}

SYSTEM=$(detect_system)

if [[ "$SYSTEM" == "unsupported" || "$SYSTEM" == "unknown" ]]; then
    echo -e "${RED}❌ Sistema não suportado! Este script funciona apenas em Debian ou Ubuntu.${NC}"
    exit 1
fi

# Obter versão e codinome do sistema com fallback seguro
if command -v lsb_release &> /dev/null; then
    OS_VERSION=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    OS_CODENAME=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')
fi

# === VARIÁVEIS DE CONFIGURAÇÃO ===
INSTALL_DIR="/opt/grafana-docker"
GF_USER="admin"
GF_PASS="admin"
TIMEZONE="America/Sao_Paulo"

show_splash() {
    clear
    echo -e "\e[34m"
    echo " ██████╗ ██████╗  █████╗ ███████╗ █████╗ ███╗   ██╗ █████╗ "
    echo "██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔══██╗"
    echo "██║  ███╗██████╔╝███████║█████╗  ███████║██╔██╗ ██║███████║"
    echo "██║   ██║██╔══██╗██╔══██║██╔══╝  ██╔══██║██║╚██╗██║██╔══██║"
    echo "╚██████╔╝██║  ██║██║  ██║██║     ██║  ██║██║ ╚████║██║  ██║"
    echo " ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝"
    echo -e "\e[0m"
    echo "========================================================"
    echo "      INSTALADOR GRAFANA OSS - DOCKER COMPOSE"
    echo "      PARA ${SYSTEM^^} $OS_VERSION ($OS_CODENAME)"
    echo "========================================================"
    echo ""
    sleep 2
}

show_splash

echo -e "${BLUE}========================================================${NC}"
echo -e "          ${YELLOW}🚀 Instalação Automatizada Segura${NC}"
echo -e "          ${YELLOW}📜 Grafana Dashboard (Container)${NC}"
echo -e "${BLUE}========================================================${NC}"

# === ETAPA 1: ATUALIZAÇÃO DO SISTEMA E DEPENDÊNCIAS ===
echo -e "\n${GREEN}🔄 [ETAPA 1/5] Verificando dependências essenciais...${NC}"
DEPS=("wget" "curl" "gpg" "lsb_release")
MISSING_DEPS=0

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS=1
        break
    fi
done

if [ "$MISSING_DEPS" -eq 1 ]; then
    apt update -y
    apt install -y apt-transport-https software-properties-common wget curl gnupg2 ca-certificates lsb-release
else
    echo -e "  ✔ Dependências essenciais já estão instaladas."
fi

timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true

# === ETAPA 2: VERIFICAÇÃO E INSTALAÇÃO DO DOCKER ===
echo -e "\n${GREEN}🐳 [ETAPA 2/5] Verificando Docker e Docker Compose...${NC}"
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    echo -e "  ✔ Docker e Docker Compose já estão instalados."
else
    echo -e "${YELLOW}Instalando Docker e Docker Compose a partir do repositório oficial...${NC}"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${SYSTEM}/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${SYSTEM} \
      ${OS_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "  ✔ Docker instalado com sucesso."
fi

systemctl enable docker &>/dev/null
systemctl start docker

# === ETAPA 3: CRIAÇÃO DO DOCKER-COMPOSE.YML ===
echo -e "\n${GREEN}📊 [ETAPA 3/5] Configurando o ambiente Docker do Grafana em ${INSTALL_DIR}...${NC}"
mkdir -p "$INSTALL_DIR"

# Verifica se a rede do Zabbix existe para conectar o Grafana diretamente a ela
if docker network ls --format '{{.Name}}' | grep -q "^zabbix-docker_zabbix-net$"; then
    ZBX_NET_CONFIG="  zabbix-net:
    external: true
    name: zabbix-docker_zabbix-net"
    SERVICE_NET="      - grafana-net
      - zabbix-net"
    echo -e "  ✔ Rede do Zabbix detectada! Integrando o Grafana automaticamente à rede do Zabbix."
else
    ZBX_NET_CONFIG=""
    SERVICE_NET="      - grafana-net"
fi

cat <<EOF > "${INSTALL_DIR}/docker-compose.yml"
services:
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    restart: unless-stopped
    environment:
      - TZ=${TIMEZONE}
      - GF_SECURITY_ADMIN_USER=${GF_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GF_PASS}
      - GF_INSTALL_PLUGINS=alexanderzobnin-zabbix-app
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
${SERVICE_NET}
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  grafana-net:
    driver: bridge
${ZBX_NET_CONFIG}

volumes:
  grafana_data:
EOF

# === ETAPA 4: INICIALIZAÇÃO DO CONTAINER ===
echo -e "\n${GREEN}📦 [ETAPA 4/5] Baixando imagem, instalando plugin do Zabbix e iniciando o Grafana...${NC}"
cd "$INSTALL_DIR"
if ! docker compose up -d; then
    echo -e "\n${RED}❌ ERRO: Falha ao iniciar o container do Grafana. Verifique sua conexão ou conflito na porta 3000.${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Aguardando o serviço web do Grafana ficar online...${NC}"
TIMEOUT=60
ELAPSED=0
while [ "$(docker inspect -f '{{.State.Health.Status}}' grafana 2>/dev/null)" != "healthy" ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo -e "\n${YELLOW}⚠️ O container iniciou, mas a verificação de saúde demorou mais que o esperado.${NC}"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo -n "."
done
echo -e "\n  ✔ Container ${GREEN}grafana${NC}: Ativo e operacional!"

# === ETAPA 5: CONFIGURAÇÃO DO FIREWALL ===
echo -e "\n${GREEN}🔥 [ETAPA 5/5] Configurando firewall...${NC}"
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 3000/tcp comment "Grafana Web UI" &>/dev/null
    ufw reload &>/dev/null
    echo -e "Porta liberada no UFW: ${YELLOW}3000/tcp (Grafana Web UI)${NC}"
else
    echo -e "  ✔ UFW inativo ou não instalado (porta 3000 já exposta pelo Docker)."
fi

SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -I | awk '{print $1}')

# === INFORMAÇÕES DE ACESSO ===
echo -e "\n${GREEN}✅ ✅ ✅ Instalação do Grafana concluída com sucesso! ✅ ✅ ✅${NC}"
echo -e "${BLUE}========================================================${NC}"
echo -e "🌐 ${YELLOW}ACESSO AO PAINEL DO GRAFANA:${NC}"
echo -e "   URL:      ${GREEN}http://${SERVER_IP}:3000${NC}"
echo -e "   Usuário:  ${YELLOW}${GF_USER}${NC}"
echo -e "   Senha:    ${YELLOW}${GF_PASS}${NC} (Você pode alterar pelo menu Profile)"
echo -e "   Plugin:   ${GREEN}Zabbix Plugin já pré-instalado!${NC}"
echo -e "${BLUE}========================================================${NC}"
echo -e "🛠️ ${YELLOW}COMANDOS ÚTEIS:${NC}"
echo -e "   Verificar status: ${YELLOW}docker compose -f ${INSTALL_DIR}/docker-compose.yml ps${NC}"
echo -e "   Reiniciar painel: ${YELLOW}docker compose -f ${INSTALL_DIR}/docker-compose.yml restart${NC}"
echo -e "   Ver logs:         ${YELLOW}docker compose -f ${INSTALL_DIR}/docker-compose.yml logs -f${NC}"
echo -e "${BLUE}========================================================${NC}"