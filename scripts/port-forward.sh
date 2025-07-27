#!/bin/bash

# Cores para formatação
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    StackFood - Port Forward Helper       ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Encerrar processos de port-forward existentes
echo -e "${YELLOW}[INFO]${NC} Encerrando processos de port-forward existentes..."
pkill -f "kubectl port-forward" &>/dev/null || true

# Definir portas
HTTP_PORT=5039
HTTPS_PORT=7189

# Iniciar port-forward para HTTP
echo -e "${YELLOW}[INFO]${NC} Configurando port-forward HTTP na porta ${HTTP_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTP_PORT}:5039 -n stackfood-dev > /dev/null 2>&1 &
HTTP_PID=$!
sleep 1

# Iniciar port-forward para HTTPS
echo -e "${YELLOW}[INFO]${NC} Configurando port-forward HTTPS na porta ${HTTPS_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTPS_PORT}:7189 -n stackfood-dev > /dev/null 2>&1 &
HTTPS_PID=$!
sleep 1

# Verificar se os port-forwards estão funcionando
echo -e "${YELLOW}[INFO]${NC} Verificando conectividade com a API..."

if ps -p $HTTP_PID > /dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Port-forward HTTP está rodando (PID: $HTTP_PID)"
    echo -e "🌐 API HTTP: ${YELLOW}http://localhost:${HTTP_PORT}${NC}"
    echo -e "🌐 Swagger HTTP: ${YELLOW}http://localhost:${HTTP_PORT}/swagger/index.html${NC}"
else
    echo -e "${RED}[ERROR]${NC} Port-forward HTTP falhou"
fi

if ps -p $HTTPS_PID > /dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Port-forward HTTPS está rodando (PID: $HTTPS_PID)"
    echo -e "🌐 API HTTPS: ${YELLOW}https://localhost:${HTTPS_PORT}${NC}"
    echo -e "🌐 Swagger HTTPS: ${YELLOW}https://localhost:${HTTPS_PORT}/swagger/index.html${NC}"
else
    echo -e "${RED}[ERROR]${NC} Port-forward HTTPS falhou"
fi

echo -e ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}EXEMPLO DE REQUISIÇÃO:${NC}"
echo -e "${BLUE}curl -X 'POST' \\
'http://localhost:${HTTP_PORT}/api/customers' \\
-H 'accept: */*' \\
-H 'Content-Type: application/json' \\
-d '{
\"name\": \"Cliente PAGO\",
\"email\": \"teste@gmail.com\",
\"cpf\": \"42226461647\"
}'${NC}"
echo -e "${BLUE}==========================================${NC}"