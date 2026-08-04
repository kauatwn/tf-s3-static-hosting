# Infraestrutura Segura de Site Estático Entregue na Borda (Edge)

Uma infraestrutura de hospedagem estática cloud-native construída para aplicações web modernas (**Vite / Tailwind CSS / SPA**). Construído para simular um ambiente seguro de entrega em nuvem na borda (_edge delivery_), este projeto serve como um estudo de caso de engenharia para explorar padrões de provisionamento de infraestrutura em nuvem, integrando especificamente **Amazon S3**, **AWS CloudFront (com Origin Access Control - OAC)**, **AWS WAFv2**, **Amazon Route 53** e **Amazon CloudWatch** utilizando **Terraform** como Infraestrutura como Código (IaC).

O foco principal desta aplicação não é a lógica de negócios complexa do frontend, mas sim o provisionamento automatizado, a orquestração de serviços gerenciados na borda, a implementação de um perímetro de armazenamento _zero-trust_ e o domínio do ecossistema AWS (via LocalStack). É um estudo de caso projetado para tornar conceitos estruturais cloud-native tangíveis, lidando com roteamento de rede na borda, restrições declarativas de variáveis, isolamento seguro da origem, modularidade da infraestrutura e observabilidade operacional.

## Índice

- [Pré-requisitos](#pré-requisitos)
- [Como Executar](#como-executar)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Arquitetura e Princípios de Design](#arquitetura-e-princípios-de-design)
- [Mergulho Profundo na Infraestrutura](#mergulho-profundo-na-infraestrutura)
- [CI/CD e Portões de Automação](#cicd-e-portões-de-automação)
- [Limitações Conhecidas e Trade-offs Pragmáticos](#limitações-conhecidas-e-trade-offs-pragmáticos)

## Pré-requisitos

Certifique-se de ter os seguintes itens instalados para executar este projeto de forma eficiente em seu ambiente local:

- **[Node.js](https://nodejs.org/)**
- **[Terraform](https://developer.hashicorp.com/terraform/install)**
- **[Docker](https://www.docker.com/)** (Necessário para rodar o container de emulação do LocalStack)
- **[LocalStack AWS CLI (awslocal)](https://docs.localstack.cloud/user-guide/integrations/aws-cli/#awslocal)** (Um _wrapper_ leve do AWS CLI pré-configurado para os endpoints do LocalStack)

## Como Executar

Siga estes passos granulares para iniciar o ambiente de nuvem local, compilar os artefatos do frontend e provisionar a infraestrutura completa.

### 1. Clone o Repositório

Baixe o código-fonte para a sua máquina local:

```bash
git clone https://github.com/kauatwn/tf-s3-static-hosting.git
```

### 2. Navegue para a Pasta do Projeto

```bash
cd tf-s3-static-hosting
```

### 3. Inicie o Ambiente de Nuvem Local

Suba o container do LocalStack Pro em segundo plano para emular os serviços de nuvem da AWS localmente, sem gerar custos reais:

```bash
docker-compose up -d
```

### 4. Instale as Dependências do Frontend

Instale todos os pacotes utilizando o _lockfile_ congelado para garantir a consistência do ambiente de desenvolvimento:

```bash
pnpm install --frozen-lockfile
```

### 5. Faça o Build da Aplicação Web Vite

Compile e otimize os artefatos estáticos de produção do frontend:

```bash
pnpm run build
```

_Nota: Isso gera os artefatos de build de produção altamente otimizados dentro do diretório local `./dist`._

### 6. Navegue para o Diretório do Ambiente

Mova-se para a pasta específica do ambiente de desenvolvimento do Terraform antes de executar as tarefas de provisionamento:

```bash
cd infra/environments/dev
```

### 7. Inicialize o Terraform

Baixe os plugins dos _providers_ necessários e inicialize o estado local (backend):

```bash
terraform init
```

### 8. Planeje a Infraestrutura

Gere e inspecione um plano de execução para visualizar todos os recursos que serão construídos antes de aplicar as mudanças:

```bash
terraform plan -out=tfplan
```

### 9. Aplique a Infraestrutura

Execute o plano verificado de forma não-interativa para provisionar seus recursos locais da AWS:

```bash
terraform apply -input=false tfplan
```

> [!TIP]
> O Terraform exibirá os valores gerados dinamicamente ao final do processo: `s3_bucket_name`, `cloudfront_distribution_id`, `cloudfront_domain_name` e `route53_name_servers`.

### 10. Faça o Deploy dos Artefatos

Faça o upload dos arquivos estáticos para o bucket S3 (que é completamente privado):

```bash
awslocal s3 sync ../../../dist s3://$(terraform output -raw s3_bucket_name) --delete
```

### 11. Invalide o Cache da Borda (Edge)

Limpe o cache da distribuição do CloudFront para garantir que suas atualizações fiquem disponíveis globalmente de forma instantânea:

```bash
awslocal cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/*"
```

## Estrutura do Projeto

A base de código está organizada seguindo os **princípios de IaC Modular**, segregando de forma limpa os blocos de infraestrutura reutilizáveis (Pure Modules) da orquestração do ambiente (Glue Code) e do código-fonte do frontend.

```plaintext
tf-s3-static-hosting/
├── .github/workflows/
│   └── pipeline.yml                      # Workflow automatizado do GitHub Actions
├── dist/                                 # Saída do build de produção do Vite
├── src/                                  # Camada de código-fonte do frontend
├── infra/
│   ├── environments/
│   │   └── dev/                          # Ponto de entrada do ambiente de desenvolvimento
│   │       ├── main.tf                   # Orquestração raiz & Glue Code (Código Cola)
│   │       ├── outputs.tf                # Integração com CI/CD & outputs para o CLI
│   │       ├── providers.tf              # Configuração do AWS Provider para o LocalStack
│   │       ├── variables.tf              # Variáveis de ambiente & Validações de entrada
│   │       └── terraform.tfvars.example  # Exemplo de valores para deploy local
│   └── modules/
│       ├── cdn/                          # CloudFront, OAC, Security Headers & Roteamento SPA
│       ├── dns/                          # Zona do Route 53 & Registros Alias (A/AAAA)
│       ├── monitoring/                   # Alarmes CloudWatch (Erros 5xx, Bloqueios WAF)
│       ├── storage/                      # Bucket S3 Privado & Bloqueios de Acesso Público
│       └── waf/                          # WAFv2 Web ACL, Rate Limiting & Regras OWASP
├── docker-compose.yml                    # Configuração do container LocalStack
└── package.json                          # Scripts de automação e ferramentas de pacotes
```

## Arquitetura e Princípios de Design

Este repositório prioriza uma **Arquitetura Serverless Entregue na Borda (Edge-Delivered)** associada a padrões estritos de **Inversão de Controle (IoC)** dentro do Terraform.

### 1. Ciclo de Vida da Requisição Protegida na Borda

_(Coloque a imagem do diagrama da sua arquitetura dentro da pasta assets e faça a referência abaixo)_

_Figura 1: Pipeline síncrono de requisições na borda, desde a resolução DNS no Route 53, passando pelo WAFv2 e cache do CloudFront, até a origem privada no S3._

- **O Ponto de Entrada (Entrypoint):** O cliente resolve o domínio através do **Amazon Route 53** usando registros Alias `A`/`AAAA` apontando diretamente para a rede de borda da CDN.
- **O Perímetro da Borda (Edge Perimeter):** Antes de chegar a qualquer camada de armazenamento, as requisições passam pelo **AWS WAFv2** para inspeção de Camada 7, incluindo _rate limiting_ e regras gerenciadas (AWS Managed Rules).
- **O Cache de Entrega (Delivery Cache):** O **AWS CloudFront** processa a terminação TLS, aplica cabeçalhos de segurança HTTP, gerencia as políticas de cache na borda e lida com as reescritas de roteamento no lado do cliente para a Single Page Application (SPA).
- **O Cofre de Armazenamento (Storage Vault):** O conteúdo reside em um bucket **Amazon S3** totalmente selado da internet através de um bloqueio explícito de acesso público. Ele aceita operações de leitura _apenas_ quando autorizadas através do **CloudFront Origin Access Control (OAC)**.

### 2. Padrões de Design e Recursos Arquiteturais

| Recurso / Padrão           | Cenário de Uso                                                                                | Implementação                                                                                                                                  |
| -------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pure Modules (IoC)**     | Eliminar dependências circulares e o forte acoplamento de recursos dentro dos módulos HCL.    | Módulos reutilizáveis em `/infra/modules/` aceitam dependências como variáveis tipadas; o módulo raiz atua como o **Glue Code** (Código Cola). |
| **Origem Zero-Trust**      | Prevenir que usuários ignorem a CDN e acessem o S3 diretamente.                               | Aplicado por `aws_s3_bucket_public_access_block` e uma política de bucket explícita para o Service Principal do CloudFront.                    |
| **Tipagem Fail-Fast**      | Capturar erros de nomenclatura e configuração antes que as requisições cheguem à API da AWS.  | Blocos `validation {}` no Terraform com expressões regulares estruturais dentro da configuração do ambiente.                                   |
| **Roteamento Cliente SPA** | Prevenir falhas HTTP 403/404 quando os usuários acessam rotas do lado do cliente diretamente. | O `custom_error_response` do CloudFront mapeia os erros da origem de volta para `/index.html` com uma resposta `200 OK`.                       |
| **Métricas Pró-ativas**    | Detectar falhas na origem e padrões de tráfego incomuns.                                      | Alarmes do **Amazon CloudWatch** rastreando as métricas `5xxErrorRate` do CloudFront e `BlockedRequests` do WAF.                               |

### 3. Pure Modules (Módulos Puros) e Glue Code (Código Cola)

Os módulos do Terraform seguem a abordagem de **Pure Modules**. Módulos individuais declaram o que precisam através de variáveis de entrada tipadas, em vez de depender diretamente de recursos gerenciados por outros módulos.

O módulo raiz em `infra/environments/dev/main.tf` atua como o **Glue Code**, responsável por conectar os módulos e injetar explicitamente as suas dependências.

Esta abordagem melhora a:

- **Reutilização:** Os módulos podem ser usados em diferentes contextos de infraestrutura sem ficarem presos a recursos específicos.
- **Testabilidade:** Módulos individuais podem ser validados de forma independente.
- **Manutenibilidade:** Os relacionamentos da infraestrutura permanecem visíveis ao nível do ambiente.
- **Gestão de Dependências:** As relações entre os módulos são definidas explicitamente em vez de ficarem ocultas dentro dos componentes reutilizáveis.

Isso evita designs fortemente acoplados, como um módulo S3 exigir diretamente o ID de uma distribuição do CloudFront para funcionar.

## Mergulho Profundo na Infraestrutura

### 1. Gerenciamento e Validação de Variáveis

As variáveis de ambiente utilizam tipagem estrita no Terraform para agrupar as configurações de forma coesa. Entradas críticas incluem blocos `validation {}` seguindo uma abordagem **Fail-Fast** (Falhe Rápido), prevenindo que configurações inválidas cheguem à API da AWS.

Por exemplo, as restrições de nomenclatura do bucket S3 podem ser validadas usando expressões regulares antes do Terraform tentar provisionar o recurso.

As tags dos recursos são padronizadas através de `locals` centralizados no Terraform, permitindo que metadados comuns sejam aplicados consistentemente em todos os recursos da infraestrutura.

### 2. Camada de Armazenamento (`storage`)

O módulo `storage` provisiona a origem privada no S3.

O bucket utiliza o `aws_s3_bucket_public_access_block` para impedir o acesso público. Nenhum acesso público de leitura é necessário porque os objetos são servidos através do CloudFront.

O acesso à origem é restrito à distribuição do CloudFront através do **Origin Access Control (OAC)**, criando uma fronteira de segurança clara entre a borda pública e a camada de armazenamento.

### 3. Entrega na Borda e Segurança (`cdn` & `waf`)

Os módulos `cdn` e `waf` fornecem a camada pública de entrega e segurança.

- **CloudFront OAC:** Utiliza o Origin Access Control e a assinatura de requisições SigV4 para autenticar as chamadas do CloudFront para o bucket S3.
- **WAFv2 Web ACL:** Anexa um Web Application Firewall ao CloudFront, utilizando limitação de taxa (rate limiting) por IP e o conjunto de regras comuns gerenciadas da AWS (Managed Rules Common Rule Set).
- **Suporte a Roteamento SPA:** O CloudFront intercepta as respostas `403` e `404` geradas pela origem S3 e as mapeia para `/index.html` com uma resposta `200 OK`, permitindo que o roteador no lado do cliente do Vite lide com a rota solicitada.
- **Política de Cabeçalhos de Segurança (Security Headers):** Injeta `Strict-Transport-Security`, `X-Content-Type-Options` e `X-Frame-Options` diretamente na borda.
- **Cache na Borda (Edge Caching):** O CloudFront faz o cache dos artefatos estáticos nas _edge locations_, reduzindo requisições repetidas à origem S3.

### 4. Resolução de DNS (`dns`)

O módulo `dns` gerencia a Hosted Zone no Amazon Route 53 e cria registros Alias `A` e `AAAA` apontando para a distribuição do CloudFront.

Isso permite que tanto os clientes IPv4 quanto IPv6 resolvam a aplicação através da rede global do CloudFront.

### 5. Observabilidade (`monitoring`)

O módulo `monitoring` provisiona os alarmes do **Amazon CloudWatch** para visibilidade operacional ao nível da infraestrutura.

A configuração atual monitora:

- O `5xxErrorRate` do CloudFront, com um limiar de alerta de 5%.
- O `BlockedRequests` do WAF, com um limiar de alerta de 100 requisições dentro de uma janela de avaliação de 5 minutos.

Essas métricas fornecem visibilidade sobre potenciais falhas na origem e padrões de tráfego incomuns.

## CI/CD e Portões de Automação

O workflow configurado em `pipeline.yml` fornece validação de ponta a ponta (_end-to-end_) contra um ambiente efêmero do LocalStack dentro do _runner_ de integração contínua.

### Integração Contínua (`ci-build`)

A etapa de CI:

1. Valida a formatação do código através de `format:check`.
2. Instala as dependências do frontend utilizando `pnpm install --frozen-lockfile`.
3. Compila a aplicação Vite.
4. Faz o upload do diretório `dist` gerado como um artefato do workflow.

Isso separa a compilação da aplicação do deploy da infraestrutura, e garante que apenas os artefatos de frontend construídos com sucesso avancem para o deploy.

### Implantação Contínua (`cd-deploy-localstack`)

A etapa de deploy:

1. Inicia um ambiente isolado do LocalStack.
2. Executa as verificações de formatação do Terraform com `terraform fmt -check`.
3. Inicializa o Terraform.
4. Roda `terraform validate`.
5. Gera o plano de execução do Terraform.
6. Aplica a infraestrutura sem necessidade de inputs manuais.
7. Baixa o artefato de build do frontend.
8. Sincroniza os ativos compilados para o S3.
9. Invalida o cache da distribuição do CloudFront.

Isso permite que todo o processo de provisionamento da infraestrutura e deploy dos artefatos estáticos seja validado automaticamente dentro do ambiente de CI.

## Limitações Conhecidas e Trade-offs Pragmáticos

Sendo um estudo de caso de engenharia centrado na entrega serverless na borda, algumas decisões arquiteturais impõem limitações que devem ser consideradas para cargas de trabalho de produção públicas.

| Recurso / Decisão           | Cenário de Uso                                                                                  | Implementação / Trade-off                                                                                                                                                                                                                                                                    |
| --------------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Vite SPA Fallback**       | Servir Single Page Applications onde rotas no cliente não existem como objetos físicos no S3.   | O CloudFront mapeia respostas `403/404` para `/index.html`. _Trade-off: Verdadeiras respostas HTTP 404 e Server-Side Rendering (SSR) não estão disponíveis neste setup puramente estático._                                                                                                  |
| **Rate Limiting do WAF**    | Reduzir tráfego abusivo e requisições desnecessárias ao CloudFront.                             | Utiliza um limiar de requisições fixo e uma janela de avaliação. _Trade-off: O limiar deve ser ajustado com cuidado para evitar o bloqueio de usuários legítimos que compartilham o mesmo IP público através de gateways NAT corporativos._                                                  |
| **Emulação com LocalStack** | Testar a infraestrutura localmente sem custos recorrentes da AWS ou credenciais reais de nuvem. | Utiliza configuração específica do provider para o LocalStack e credenciais mockadas (falsas). _Trade-off: O comportamento global do CloudFront, a latência geográfica, a propagação na borda e as características de rede de produção não podem ser perfeitamente reproduzidas localmente._ |
| **OAC vs OAI**              | Restringir o acesso ao S3 exclusivamente para o CloudFront.                                     | Utiliza o modelo moderno **Origin Access Control (OAC)** em vez da abordagem legada **Origin Access Identity (OAI)**, suportando assinatura de requisições via SigV4.                                                                                                                        |

### Reescrita de Erros em SPA & SEO

O fallback (plano de contingência) para SPA fornece um mecanismo conveniente para o roteamento no lado do cliente, mas possui um _trade-off_ de SEO (Otimização para Motores de Busca).

Como o CloudFront retorna `/index.html` com o status `200 OK` para rotas que não correspondem a objetos reais no S3, as rotas que não existem não podem retornar naturalmente uma verdadeira resposta HTTP `404`.

Para aplicações onde o SEO é crítico, a arquitetura precisaria evoluir em direção à renderização no lado do servidor (SSR) ou renderização híbrida, utilizando potencialmente serviços como o Lambda@Edge ou o CloudFront Functions onde apropriado.

### Fronteiras da Emulação Local

O LocalStack fornece um ambiente eficiente para validar configurações do Terraform e _workflows_ de deploy sem incorrer em custos de infraestrutura da AWS.

No entanto, ele não pode reproduzir perfeitamente o comportamento da rede de borda global da AWS. Características como latência geográfica, propagação na borda global, comportamento de cache regional e performance da rede/TLS de produção podem diferir da infraestrutura real da AWS.

O LocalStack deve, portanto, ser tratado como um **ambiente de desenvolvimento e validação de infraestrutura**, e não como um substituto completo para testes em uma conta AWS de produção.
