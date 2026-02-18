# NGINX Ingress Controller - Public

Este módulo provisiona um NGINX Ingress Controller com NLB **internet-facing** para aplicações públicas como ArgoCD e Grafana.

## Diferença do nginx-ingress padrão

- **IngressClass**: `nginx-public` (ao invés de `nginx`)
- **NLB**: Internet-facing com IP público
- **Namespace**: `ingress-nginx-public`
- **Uso**: Ferramentas de gestão e monitoramento que precisam ser acessíveis externamente

## Como usar nos Ingress resources

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
spec:
  ingressClassName: nginx-public # Use esta classe
  rules:
    - host: argocd.optimus-frame.com.br
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```
