#!/bin/bash
set -e

# Definindo cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    StackFood - Ambiente de Teste Local   ${NC}"
echo -e "${BLUE}    Versão Otimizada para Port-Forward    ${NC}"
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
print_step "Criando namespace de desenvolvimento..."
kubectl apply -f ../apps/namespaces/dev-namespace.yaml
check_success "Namespace criado com sucesso." "Falha ao criar namespace."
sleep 2

# Aplicar secrets
print_step "Aplicando GitHub Container Registry Secret..."
kubectl apply -f ../apps/shared/secrets/ghcr-secret.yaml -n stackfood-dev
check_success "Secret aplicado com sucesso." "Falha ao aplicar secret."

# Aplicar manifestos
print_step "Aplicando manifestos do banco de dados..."
kubectl apply -k ../apps/db/base -n stackfood-dev
kubectl apply -k ../apps/db/dev -n stackfood-dev
check_success "Manifestos do banco de dados aplicados." "Falha ao aplicar manifestos do banco de dados."

print_step "Aplicando manifestos da API..."
kubectl apply -k ../apps/api/base -n stackfood-dev
kubectl apply -k ../apps/api/dev -n stackfood-dev
check_success "Manifestos da API aplicados." "Falha ao aplicar manifestos da API."

# Aguardar recursos serem criados
print_step "Aguardando criação inicial dos recursos..."
sleep 5

# Verificar pods
print_step "Verificando status dos pods:"
kubectl get pods -n stackfood-dev
print_info "Pods em ContainerCreating ou Pending são normais durante a inicialização."

# Aguardar pods ficarem prontos
print_step "Aguardando pods da API ficarem prontos..."
if kubectl wait --for=condition=ready pod -l app=stackfood-api --timeout=180s -n stackfood-dev; then
  print_success "Pods da API prontos!"
else
  print_info "Verificando status dos pods da API..."
  kubectl describe pods -l app=stackfood-api -n stackfood-dev | grep -A 10 "Events:"
  print_info "Continuando mesmo assim..."
fi

print_step "Aguardando pods do banco de dados ficarem prontos..."
if kubectl wait --for=condition=ready pod -l app=stackfood-db --timeout=180s -n stackfood-dev; then
  print_success "Pods do banco de dados prontos!"
else
  print_info "Verificando status dos pods do banco de dados..."
  kubectl describe pods -l app=stackfood-db -n stackfood-dev | grep -A 10 "Events:"
  print_info "Continuando mesmo assim..."
fi

# Mostrar recursos criados
print_step "Recursos criados:"
echo ""
echo "Deployments:"
kubectl get deployments -n stackfood-dev
echo ""
echo "StatefulSets:"
kubectl get statefulsets -n stackfood-dev
echo ""
echo "Services:"
kubectl get services -n stackfood-dev
echo ""
echo "ConfigMaps:"
kubectl get configmaps -n stackfood-dev
echo ""

# Configurar port-forward (método único para acessar a API)
print_step "Configurando port-forward para acesso à API..."

# Definir portas
HTTP_PORT=8080
HTTPS_PORT=8443

# Iniciar port-forward para HTTP
print_info "Configurando port-forward HTTP na porta ${HTTP_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTP_PORT}:5039 -n stackfood-dev > /dev/null 2>&1 &
HTTP_PID=$!
sleep 2

# Iniciar port-forward para HTTPS (importante para swagger)
print_info "Configurando port-forward HTTPS na porta ${HTTPS_PORT}..."
nohup kubectl port-forward svc/stackfood-api ${HTTPS_PORT}:7189 -n stackfood-dev > /dev/null 2>&1 &
HTTPS_PID=$!
sleep 2

# Verificar se os port-forwards estão funcionando
if ps -p $HTTP_PID > /dev/null; then
    print_success "Port-forward HTTP está rodando (PID: $HTTP_PID)"
    echo -e "🌐 API HTTP: ${YELLOW}http://localhost:${HTTP_PORT}${NC}"
    echo -e "🌐 Swagger HTTP: ${YELLOW}http://localhost:${HTTP_PORT}/swagger/index.html${NC}"
else
    print_error "Port-forward HTTP falhou"
fi

if ps -p $HTTPS_PID > /dev/null; then
    print_success "Port-forward HTTPS está rodando (PID: $HTTPS_PID)"
    echo -e "🌐 API HTTPS: ${YELLOW}https://localhost:${HTTPS_PORT}${NC}"
    echo -e "🌐 Swagger HTTPS: ${YELLOW}https://localhost:${HTTPS_PORT}/swagger/index.html${NC}"
else
    print_error "Port-forward HTTPS falhou"
fi

# Verificar conectividade HTTP
print_step "Verificando conectividade com a API (HTTP)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HTTP_PORT}/swagger/index.html | grep -q "200"; then
  print_success "API HTTP está acessível via port-forward!"
else
  print_error "Não foi possível acessar a API via HTTP. Verificando logs..."
  kubectl logs -l app=stackfood-api -n stackfood-dev --tail=20
fi

echo -e "\n${BLUE}==========================================${NC}"
echo -e "${GREEN}       AMBIENTE DE TESTES PRONTO!        ${NC}"
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
echo -e ""
echo -e "${YELLOW}[INFORMAÇÕES ÚTEIS]${NC}"
echo -e "Para verificar logs da API:"
echo -e "${BLUE}kubectl logs -l app=stackfood-api -n stackfood-dev --tail=50${NC}"
echo -e ""
echo -e "Para verificar logs do banco de dados:"
echo -e "${BLUE}kubectl logs -l app=stackfood-db -n stackfood-dev --tail=50${NC}"
echo -e ""
echo -e "Para reiniciar os port-forwards:"
echo -e "${BLUE}./port-forward.sh${NC}"
echo -e ""
echo -e "${YELLOW}[LIMPEZA DO AMBIENTE]${NC}"
echo -e "Quando terminar os testes, execute:"
echo -e "${BLUE}kubectl delete namespace stackfood-dev${NC}"
echo -e "${BLUE}pkill -f \"kubectl port-forward\"${NC}"
echo -e "${BLUE}==========================================${NC}"