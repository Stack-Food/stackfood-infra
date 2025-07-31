#!/bin/bash
# filepath: /home/luizf/fiap/stackfood-infra/scripts/deploy-stack.sh
set -e

# Verificar argumento de ambiente
if [ "$1" == "dev" ]; then
    ENVIRONMENT="dev"
    NAMESPACE="stackfood-dev"
    HTTP_PORT=5039
    HTTPS_PORT=7189
    DB_PORT=5432
    ENV_DISPLAY="Desenvolvimento"
elif [ "$1" == "prod" ]; then
    ENVIRONMENT="prod"
    NAMESPACE="stackfood-prod"
    HTTP_PORT=5039
    HTTPS_PORT=7189
    DB_PORT=5432
    ENV_DISPLAY="Produção"
    
    # Confirmação para ambiente de produção
    echo -e "${RED}ATENÇÃO: Você está prestes a modificar o ambiente de PRODUÇÃO.${NC}"
    read -p "Deseja continuar? (sim/não): " choice
    if [[ ! "$choice" =~ ^[Ss][Ii][Mm]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
else
    echo "Uso: $0 [dev|prod]"
    echo "  dev  - Implanta no ambiente de desenvolvimento"
    echo "  prod - Implanta no ambiente de produção"
    exit 1
fi

# Definindo cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    StackFood - Ambiente de ${ENV_DISPLAY}    ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Funções de formatação
print_step() { echo -e "${YELLOW}[STEP]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Função para verificar sucesso
check_success() {
  if [ $? -eq 0 ]; then
    print_success "$1"
  else
    print_error "$2"
    exit 1
  fi
}

# Limpar processos anteriores
print_step "Limpando processos anteriores..."
pkill -f "kubectl port-forward" &>/dev/null || true
print_info "Processos anteriores encerrados."

# Verificar Minikube
print_step "Verificando status do Minikube..."
if ! minikube status &>/dev/null; then
  print_info "Minikube não está rodando. Iniciando..."
  minikube start --driver=docker
  check_success "Minikube iniciado com sucesso." "Falha ao iniciar o Minikube."
else
  print_info "Minikube já está rodando."
fi

# Criar namespace
print_step "Criando namespace ${NAMESPACE}..."
kubectl apply -f ../apps/namespaces/${ENVIRONMENT}-namespace.yaml
check_success "Namespace criado com sucesso." "Falha ao criar namespace."
sleep 2

# Aplicar secrets
print_step "Aplicando GitHub Container Registry Secret..."
kubectl apply -f ../apps/api/${ENVIRONMENT}/ghcr-secret.yaml -n ${NAMESPACE}
check_success "Secret aplicado com sucesso." "Falha ao aplicar secret."

# Aplicar manifestos
print_step "Aplicando manifestos do banco de dados..."
kubectl apply -k ../apps/db/base -n ${NAMESPACE}
kubectl apply -k ../apps/db/${ENVIRONMENT} -n ${NAMESPACE}
check_success "Manifestos do banco de dados aplicados." "Falha ao aplicar manifestos do banco de dados."

print_step "Aplicando manifestos da API..."
kubectl apply -k ../apps/api/base -n ${NAMESPACE}
kubectl apply -k ../apps/api/${ENVIRONMENT} -n ${NAMESPACE}
check_success "Manifestos da API aplicados." "Falha ao aplicar manifestos da API."

# Aguardar recursos serem criados
print_step "Aguardando criação inicial dos recursos..."
sleep 5

# Verificar pods
print_step "Verificando status dos pods:"
kubectl get pods -n ${NAMESPACE}
print_info "Pods em ContainerCreating ou Pending são normais durante a inicialização."

# Aguardar pods ficarem prontos
print_step "Aguardando pods da API ficarem prontos..."
if kubectl wait --for=condition=ready pod -l app=stackfood-api --timeout=180s -n ${NAMESPACE}; then
  print_success "Pods da API prontos!"
else
  print_info "Verificando status dos pods da API..."
  kubectl describe pods -l app=stackfood-api -n ${NAMESPACE} | grep -A 10 "Events:"
  print_info "Continuando mesmo assim..."
fi

print_step "Aguardando pods do banco de dados ficarem prontos..."
if kubectl wait --for=condition=ready pod -l app=stackfood-db --timeout=180s -n ${NAMESPACE}; then
  print_success "Pods do banco de dados prontos!"
else
  print_info "Verificando status dos pods do banco de dados..."
  kubectl describe pods -l app=stackfood-db -n ${NAMESPACE} | grep -A 10 "Events:"
  print_info "Continuando mesmo assim..."
fi

# Aplicar manifestos do worker após API e DB estarem prontos
print_step "Aplicando manifestos do Worker..."
kubectl apply -k ../apps/worker/base -n ${NAMESPACE}
kubectl apply -k ../apps/worker/${ENVIRONMENT} -n ${NAMESPACE}
check_success "Manifestos do Worker aplicados." "Falha ao aplicar manifestos do Worker."

print_step "Aguardando pods do Worker ficarem prontos..."
if kubectl wait --for=condition=ready pod -l app=stackfood-worker --timeout=180s -n ${NAMESPACE}; then
  print_success "Pods do Worker prontos!"
else
  print_info "Verificando status dos pods do Worker..."
  kubectl describe pods -l app=stackfood-worker -n ${NAMESPACE} | grep -A 10 "Events:"
  print_info "Continuando mesmo assim..."
fi

# Mostrar recursos criados
print_step "Recursos criados no ambiente de ${ENV_DISPLAY}:"
echo ""
echo "Deployments:"
kubectl get deployments -n ${NAMESPACE}
echo ""
echo "StatefulSets:"
kubectl get statefulsets -n ${NAMESPACE}
echo ""
echo "Services:"
kubectl get services -n ${NAMESPACE}
echo ""
echo "ConfigMaps:"
kubectl get configmaps -n ${NAMESPACE}
echo ""

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    StackFood - Port Forward Helper       ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Definir portas
echo -e "${YELLOW}[INFO]${NC} Configurando port-forward HTTP na porta ${HTTP_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTP_PORT}:5039 -n ${NAMESPACE} > /dev/null 2>&1 &
HTTP_PID=$!
sleep 1

# Iniciar port-forward para HTTPS
echo -e "${YELLOW}[INFO]${NC} Configurando port-forward HTTPS na porta ${HTTPS_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTPS_PORT}:7189 -n ${NAMESPACE} > /dev/null 2>&1 &
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

# Configurar port-forward para o banco de dados PostgreSQL
echo -e "${YELLOW}[INFO]${NC} Configurando port-forward para o PostgreSQL na porta ${DB_PORT}..."
nohup kubectl port-forward svc/stackfood-db ${DB_PORT}:5432 -n ${NAMESPACE} > /dev/null 2>&1 &
PG_PID=$!
sleep 1

if ps -p $PG_PID > /dev/null; then
    print_success "Port-forward PostgreSQL está rodando (PID: $PG_PID)"
    echo -e "🛢️ PostgreSQL: ${YELLOW}localhost:${DB_PORT}${NC}"
    echo -e "   Database: ${YELLOW}stackfood${NC}"
    echo -e "   Username: ${YELLOW}postgres${NC}"
    echo -e "   Password: ${YELLOW}password${NC}"
else
    print_error "Port-forward PostgreSQL falhou"
fi

# Verificar status do Worker
echo -e ""
echo -e "${YELLOW}[INFO]${NC} Status do Worker:"
kubectl get pods -l app=stackfood-worker -n ${NAMESPACE}
kubectl logs --tail=10 -l app=stackfood-worker -n ${NAMESPACE}

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