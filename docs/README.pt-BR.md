# Plataforma Cloud-Native para Hospedagem Estática Edge-Delivered

## 1. O Problema e o Domínio

O alojamento de sites estáticos modernos (como Single Page Applications construídas com Vite) muitas vezes é tratado de forma negligente na nuvem, resultando em buckets de armazenamento diretamente expostos à internet, custos imprevisíveis gerados por varreduras de bots em rotas inexistentes, e ausência total de observabilidade e segurança.

O objetivo deste projeto não é explorar regras de negócios no front-end, mas sim servir como um **estudo de caso em Engenharia de Plataforma e Nuvem**. O foco é arquitetar, de forma automatizada, declarativa (IaC) e idempotente, um perímetro de entrega seguro na borda (Edge-Delivered), garantindo isolamento total do armazenamento, roteamento inteligente e princípios rígidos de controle de custos (FinOps) através do ecossistema da AWS (emulado e testado via LocalStack).

## 2. A Arquitetura da Aplicação e Padrões

O fluxo de requisições foi desenhado para uma arquitetura "Serverless Edge-Delivered", onde a infraestrutura reage às requisições o mais próximo possível do usuário final:

- **A Porta de Entrada Inteligente (DNS):** A resolução de nomes é orquestrada pelo **Amazon Route 53**, utilizando registros Alias (`A`/`AAAA`) que apontam de forma dinâmica para a rede global da CDN, suportando nativamente tráfego IPv4 e IPv6 com alta disponibilidade.

- **Segurança Perimetral e Inspeção (Layer 7):** Antes de qualquer arquivo ser servido, a requisição passa pelo **AWS WAFv2**. Ele atua como um escudo contra ataques comuns da web, implementando limitação de taxa (Rate Limiting) e bloqueando tráfego malicioso antes que ele gere custos de banda na nuvem.

- **Entrega e Roteamento de Borda:** O **AWS CloudFront** é o cérebro da operação. Ele gerencia o cache global, processa a terminação TLS, injeta cabeçalhos rígidos de segurança HTTP (ex: Anti-Clickjacking e proteção XSS) e realiza a interceptação de erros do armazenamento, direcionando requisições perdidas para a SPA ou para páginas físicas de erro (404).
- **Cofre de Armazenamento (Zero-Trust Origin):** Os artefatos compilados (HTML/CSS/JS) residem no **Amazon S3**. O bucket é configurado com bloqueio absoluto de acesso público, não possuindo rotas de internet. A leitura ocorre exclusivamente através de autenticação via **Origin Access Control (OAC)**, mediante assinatura criptográfica `sigv4` gerada pela própria CDN.

## 3. Engenharia de Segurança, Resiliência e Observabilidade

A operação de uma infraestrutura pública exige mecanismos defensivos acoplados ao ciclo de vida da requisição para evitar vazamento de dados e ataques de negação de serviço:

| Componente / Cenário | Risco Técnico | Mecanismo de Proteção | Estratégia de Implementação |
| --- | --- | --- | --- |
| **Exposição da Origem** | Acesso direto aos arquivos no bucket S3, burlando o cache e as regras de segurança do WAF. | Zero-Trust Origin com OAC | Aplicação estrita de `block_public_acls` no S3. O bucket rejeita leituras públicas, aceitando requisições autenticadas apenas do Service Principal do CloudFront associado à distribuição da conta. |
| **Roteamento SPA Híbrido** | Em SPAs, rotas de cliente (ex: `/dashboard`) geram erro no S3, prejudicando a UX e o rastreamento SEO. | Interceptação e Rewrite na Borda | Uso do `custom_error_response` no CloudFront: Erros `403` mapeiam de volta para a aplicação (`/index.html` com HTTP 200) e erros `404` entregam graciosamente uma página física de fallback (`/404.html` com HTTP 404 verdadeiro). |
| **DDoS e Scrapers na Origem** | Múltiplas requisições maliciosas gerando custos massivos de leitura direta (GET) e tráfego de saída. | Rate Limiting & Blindagem de TTL | O AWS WAF barra IPs abusivos (ex: >2000 req/5min). Se o tráfego falhar no S3, o CloudFront mantém o erro em cache por 3600s, impedindo que o ataque atinja o bucket novamente. |
| **Observabilidade Cega** | Indisponibilidade na origem ou picos de ataques sendo ignorados. | Alertas Proativos (CloudWatch) | Provisionamento de alarmes monitorando a métrica `5xxErrorRate` no CloudFront e picos de requisições na métrica `BlockedRequests` do WAF. |

## 4. Decisões Arquiteturais e Abordagem de FinOps

A escolha dos componentes e módulos foca em segurança máxima aliada a previsibilidade de custos:

- **Feature Toggles de Infraestrutura (Custo Base Zero):** O AWS WAF possui custos fixos mensais (~$5) independentes do uso. Para alinhar o projeto aos padrões de FinOps, o módulo do WAF foi implementado com condicionais (`count = var.enable_waf ? 1 : 0`). Isso permite subir ambientes de Desenvolvimento e Testes a um custo efetivo de **zero** (Escala a Zero do S3/CloudFront), ativando o escudo perimetral apenas em Produção por meio de variáveis, sem alterar o código-fonte.
- **Tags Padronizadas (DRY):** A infraestrutura adota a injeção centralizada de tags globais (`default_tags` no Provider) e mesclagem local (`merge(local.common_tags)`), garantindo estrita governança e controle de custos no *AWS Billing* sem a necessidade de repetição manual de código.
- **Validação Antecipada (Fail-Fast):** Expressões Regulares (`regex`) nos blocos de `validation {}` barram a execução do Terraform caso o desenvolvedor forneça padrões inválidos (ex: nomenclaturas ilegais para buckets S3 ou limites inseguros no WAF), preservando tempo de execução no CI/CD e chamadas desnecessárias à API da AWS.

## 5. A Infraestrutura como Código (IaC)

O provisionamento e o ciclo de vida do ambiente são gerenciados de forma declarativa e modular através do **Terraform**. O projeto adota a Inversão de Controle com o padrão de **Módulos Puros (Pure Modules)** e um **Root Module** orquestrador:

- **Módulos Puros (`/infra/modules/*`):** Componentes (`storage`, `cdn`, `waf`, `dns`, `monitoring`) são stateless e não possuem conhecimento de outros módulos. Eles recebem as dependências rigidamente tipadas (`object({})`) através de suas variáveis. O módulo S3, por exemplo, pode ser reaproveitado em outros contextos da empresa (como logs ou backups) sem necessidade de refatoração, pois não é atrelado nativamente a uma CDN.
- **Código Cola / Glue Code (`/infra/environments/dev/main.tf`):** Atua como o maestro. É responsável por instanciar os módulos, extrair o *output* de um (ex: o ARN do Web ACL) e injetar como *input* de outro (ex: as configurações da distribuição do CloudFront), garantindo um grafo de dependências linear e determinístico que elimina falhas de execução no Terraform.

## 6. Limitações Conhecidas e Trade-offs

- **Fronteiras de Emulação (LocalStack):** O ambiente conta com CI/CD que realiza testes end-to-end contra o **LocalStack Pro**. No entanto, este emulador não consegue reproduzir perfeitamente o comportamento físico da rede da AWS, como a latência geográfica, propagação global do Route 53/CloudFront ou a resiliência do protocolo TLS da infraestrutura real.
- **Renderização Híbrida e SEO:** Embora a interceptação e entrega do `/404.html` com o código de resposta correto melhore o rastreamento, a aplicação atual é inteiramente estática (SPA Client-Side). O `index.html` inicial chega vazio aos motores de busca. Para uma indexação orgânica (SEO) crítica, esta infraestrutura precisaria evoluir para integrar computação na borda (usando **Lambda@Edge** ou **CloudFront Functions** para injeção de metadados) ou adotar um framework de SSR.
