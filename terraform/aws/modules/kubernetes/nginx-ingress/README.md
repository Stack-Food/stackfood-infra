# Terraform Module: nginx-ingress

Este módulo instala o controlador Nginx Ingress em um cluster Kubernetes (EKS) usando Helm.

## Problema conhecido: Context deadline exceeded

Se você encontrar o erro "context deadline exceeded" ao aplicar este módulo, aqui estão algumas soluções:

### Solução 1: Desativar atomic e wait

Edite o arquivo `main.tf` deste módulo e altere as seguintes configurações:

```hcl
atomic = false
wait  = false
```

Isso impedirá que o Terraform espere pela conclusão da instalação, o que pode evitar o timeout.

### Solução 2: Usar o script manual

Se a Solução 1 não funcionar, você pode usar o script manual fornecido:

```bash
chmod +x /home/luizf/fiap/stackfood-infra/scripts/manual-nginx-ingress-install.sh
/home/luizf/fiap/stackfood-infra/scripts/manual-nginx-ingress-install.sh
```

Depois, comente o módulo nginx-ingress no arquivo `main.tf` principal para evitar conflitos.

### Solução 3: Verificar conectividade

Certifique-se de que:

- Você tem acesso ao cluster EKS (`kubectl cluster-info`)
- O cluster está saudável (`kubectl get nodes`)
- As credenciais estão corretamente configuradas (`aws eks update-kubeconfig`)
