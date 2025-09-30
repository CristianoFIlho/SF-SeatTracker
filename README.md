# SF-SeatTracker

Sistema de gerenciamento de assentos de cinema desenvolvido em Lightning Web Components (LWC) para Salesforce, com integração a API real de filmes e horários de cinema.

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Lightning Web Components](https://img.shields.io/badge/LWC-0176D3?style=for-the-badge&logo=salesforce&logoColor=white)
![Apex](https://img.shields.io/badge/Apex-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Uso](#uso)
- [Testes](#testes)
- [Roadmap](#roadmap)
- [Contribuindo](#contribuindo)
- [Licença](#licença)
- [Contato](#contato)

## 🎬 Sobre o Projeto

SF-SeatTracker é um sistema completo de gerenciamento de reservas de assentos de cinema desenvolvido na plataforma Salesforce. O projeto integra dados reais de filmes, cinemas e horários através da **MovieGlu API**, oferecendo uma experiência interativa para seleção e reserva de assentos.

### Objetivos

- Consumir API real (MovieGlu) para exibir filmes em cartaz, cinemas e horários
- Simular seleção e reserva de assentos de cinema
- Demonstrar arquitetura completa do ecossistema Salesforce
- Oferecer experiência responsiva com Lightning Web Components
- Automatizar processos com Flows e triggers
- Fornecer analytics através de relatórios e dashboards

## ✨ Funcionalidades

- ✅ **Busca de Filmes**: Pesquisa de filmes em cartaz por localização (geolocalização)
- ✅ **Listagem de Cinemas**: Exibição de cinemas próximos com mapa
- ✅ **Horários Disponíveis**: Visualização de sessões por filme e cinema
- ✅ **Seleção de Assentos**: Interface interativa para escolha de assentos (grid visual)
- ✅ **Reserva de Ingressos**: Processo completo de reserva com confirmação
- ✅ **Gestão de Reservas**: Acompanhamento do status das reservas (Pendente/Aprovado/Cancelado)
- ✅ **Notificações**: Envio automático de emails de confirmação
- ✅ **Relatórios**: Dashboards com métricas de ocupação e reservas
- ✅ **Portal Externo**: Experience Cloud para acesso público

## 🏗️ Arquitetura

### Camadas do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    Experience Cloud (UI)                     │
│                  (Lightning Communities)                     │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              Lightning Web Components (LWC)                  │
│  movieSearch │ showtimeSelector │ seatReservation │ confirm  │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      Apex Controllers                        │
│    MovieGluService │ ReservationController │ Triggers        │
└──────────────┬────────────────────┬─────────────────────────┘
               │                    │
       ┌───────▼────────┐   ┌──────▼──────────────────┐
       │  MovieGlu API  │   │  Custom Objects & Flows │
       │  (External)    │   │    (Data Layer)         │
       └────────────────┘   └─────────────────────────┘
```

### Objetos Customizados

| Objeto | Relacionamento | Descrição |
|--------|---------------|-----------|
| **Movie__c** | - | Armazena informações de filmes (nome, descrição, poster, ID da API) |
| **Theater__c** | - | Dados de cinemas (nome, endereço, localização geográfica) |
| **Showtime__c** | Master-Detail → Movie__c, Theater__c | Horários de sessões com preços e assentos disponíveis |
| **Reservation__c** | Lookup → Account, Movie__c, Showtime__c | Reservas com status e valor total |
| **Seat__c** | Master-Detail → Showtime__c | Assentos individuais por sessão |

## 🛠️ Tecnologias Utilizadas

### Salesforce Platform

- **Lightning Web Components (LWC)** - Framework frontend moderno
- **Apex** - Backend e lógica de negócios
- **Flows** - Automações e processos
- **Experience Cloud** - Portal externo
- **Reports & Dashboards** - Analytics e visualizações
- **Named Credentials** - Integração segura com APIs

### Integrações

- **MovieGlu API** - Dados reais de filmes e cinemas
- **Geolocation API** - Busca por proximidade

### Ferramentas de Desenvolvimento

- Salesforce CLI (SFDX)
- Visual Studio Code + Salesforce Extensions
- Git/GitHub
- Postman (para testes de API)

## 📦 Pré-requisitos

Antes de começar, você precisa ter:

- **Salesforce Developer Org** ([Criar conta gratuita](https://developer.salesforce.com/signup))
- **MovieGlu API Key** ([Registrar em developer.movieglu.com](https://developer.movieglu.com))
- **Salesforce CLI** instalado ([Guia de instalação](https://developer.salesforce.com/tools/sfdxcli))
- **Visual Studio Code** com extensões Salesforce ([Download](https://code.visualstudio.com/))
- **Git** instalado

## 🚀 Instalação

### 1. Clone o Repositório

```bash
git clone https://github.com/CristianoFIlho/SF-SeatTracker.git
cd SF-SeatTracker
```

### 2. Autentique no Salesforce

```bash
sfdx auth:web:login -a DevOrg -r https://login.salesforce.com
```

### 3. Crie um Scratch Org (Opcional)

```bash
sfdx force:org:create -f config/project-scratch-def.json -a SeatTrackerOrg -s -d 30
```

### 4. Deploy dos Metadados

```bash
sfdx force:source:push -u SeatTrackerOrg
```

### 5. Atribuir Permission Set

```bash
sfdx force:user:permset:assign -n Cinema_Reservation_Admin
```

### 6. Importar Dados de Exemplo (Opcional)

```bash
sfdx force:data:tree:import -p data/sample-data-plan.json
```

## ⚙️ Configuração

### 1. Configurar Named Credential

1. Acesse **Setup** > **Named Credentials** > **New**
2. Preencha:
   - **Label**: MovieGlu_API
   - **URL**: `https://api-gate.movieglu.com`
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: Custom
3. Em **Custom Headers**, adicione:
   ```
   x-api-key: SUA_CHAVE_API_AQUI
   client: SEU_CLIENT_ID_AQUI
   authorization: Basic BASE64_ENCODED_CREDENTIALS
   x-api-key: YOUR_API_KEY
   ```

### 2. Configurar Remote Site Settings

1. **Setup** > **Remote Site Settings** > **New**
2. **Remote Site URL**: `https://api-gate.movieglu.com`
3. Marque **Active**

### 3. Ajustar Geolocalização

No arquivo `force-app/main/default/lwc/movieSearch/movieSearch.js`, ajuste as coordenadas padrão:

```javascript
// Para São Paulo, Brasil
@track lat = '-23.5505';
@track lon = '-46.6333';
```

### 4. Configurar Experience Cloud (Opcional)

1. **Setup** > **Digital Experiences** > **All Sites** > **New**
2. Escolha template **Customer Service**
3. Nome: **Cinema Reservation Portal**
4. URL: `cinema-reserva`
5. Adicione LWC components às páginas

## 📁 Estrutura do Projeto

```
SF-SeatTracker/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/                    # Apex Classes
│           │   ├── MovieGluService.cls     # Serviço de integração com API
│           │   ├── ReservationController.cls
│           │   ├── SeatManagementService.cls
│           │   └── *Test.cls               # Classes de teste
│           ├── lwc/                        # Lightning Web Components
│           │   ├── cinemaBooking/          # Componente principal
│           │   ├── movieSearch/            # Busca de filmes
│           │   ├── showtimeSelector/       # Seleção de horários
│           │   ├── seatReservation/        # Grid de assentos
│           │   └── confirmationModal/      # Modal de confirmação
│           ├── objects/                    # Custom Objects
│           │   ├── Movie__c/
│           │   ├── Theater__c/
│           │   ├── Showtime__c/
│           │   ├── Reservation__c/
│           │   └── Seat__c/
│           ├── flows/                      # Screen Flows e Automações
│           │   └── ReservaCinemaFlow.flow
│           ├── triggers/                   # Apex Triggers
│           │   └── ShowtimeTrigger.trigger
│           ├── namedCredentials/           # API Integrations
│           │   └── MovieGlu_API.namedCredential
│           └── permissionsets/             # Permission Sets
│               └── Cinema_Reservation_Admin.permissionset
├── data/                                   # Sample Data
│   └── sample-data-plan.json
├── config/
│   └── project-scratch-def.json
├── .gitignore
├── README.md
├── sfdx-project.json
└── package.json
```

## 💻 Uso

### Para Usuários Finais

1. **Acessar Portal**: Navegue até `https://[seu-dominio].my.site.com/cinema-reserva`
2. **Buscar Filmes**: Use a barra de pesquisa ou geolocalização
3. **Selecionar Sessão**: Clique em um filme e escolha horário
4. **Escolher Assentos**: Clique nos assentos disponíveis (verdes)
5. **Confirmar Reserva**: Preencha dados e finalize
6. **Receber Confirmação**: Verifique email com detalhes da reserva

### Para Administradores

#### Sincronizar Filmes da API

```apex
// Execute no Developer Console
MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
```

#### Atualizar Horários

```apex
// Sincronizar horários de um filme específico
MovieGluService.syncShowtimes('MOVIE_ID_API', '-23.5505', '-46.6333', Date.today());
```

#### Visualizar Dashboards

1. Acesse **App Launcher** > **Cinema Management**
2. Navegue até tab **Dashboards**
3. Visualize métricas de:
   - Ocupação por cinema
   - Filmes mais reservados
   - Receita por período

## 🧪 Testes

### Executar Testes Unitários

```bash
# Todos os testes
sfdx force:apex:test:run -l RunLocalTests -w 10 -r human

# Teste específico
sfdx force:apex:test:run -n MovieGluServiceTest -r human
```

### Cobertura de Código

O projeto mantém **>75% de cobertura** em Apex:

```bash
sfdx force:apex:test:run -c -r human
```

### Testes de Integração

Mock da MovieGlu API em `MovieGluHttpCalloutMock.cls`:

```apex
@isTest
global class MovieGluHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"films":[{"film_name":"Test Movie","synopsis":"Test"}]}');
        res.setStatusCode(200);
        return res;
    }
}
```

## 🗺️ Roadmap

### Fase 1 - Core Features (Concluído)
- [x] Integração com MovieGlu API
- [x] CRUD de objetos customizados
- [x] LWC para busca e reserva
- [x] Flows para automação de emails

### Fase 2 - Melhorias (Em Progresso)
- [ ] Integração com pagamento (Stripe/PayPal)
- [ ] Notificações em tempo real (Platform Events)
- [ ] Suporte a múltiplos idiomas
- [ ] QR Code para ingressos

### Fase 3 - Avançado
- [ ] Einstein Analytics para previsões
- [ ] Chatbot com Einstein Bots
- [ ] Mobile app com Salesforce Mobile SDK
- [ ] Integração com sistemas de bilheteria real

## 🤝 Contribuindo

Contribuições são bem-vindas! Siga os passos:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Padrões de Código

- **Apex**: Siga [Apex Style Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- **LWC**: Use [Lightning Web Components Best Practices](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/)

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👤 Contato

**Cristiano Filho**

- GitHub: [@CristianoFIlho](https://github.com/CristianoFIlho)
- LinkedIn: [Seu LinkedIn](https://linkedin.com/in/seu-perfil)
- Email: seu-email@exemplo.com

---

## 📚 Recursos Adicionais

### Documentação
- [MovieGlu API Docs](https://developer.movieglu.com/docs)
- [Salesforce LWC Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Apex Integration Services Trailhead](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)

### Trailheads Recomendados
- 🎯 [Build Apps Together with Package Development](https://trailhead.salesforce.com/en/content/learn/trails/sfdx_get_started)
- 🎯 [Lightning Web Components Basics](https://trailhead.salesforce.com/content/learn/modules/lightning-web-components-basics)
- 🎯 [Apex Integration Services](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)

### Comunidade
- [Salesforce Developers Forum](https://developer.salesforce.com/forums)
- [Salesforce Stack Exchange](https://salesforce.stackexchange.com/)
- [Trailblazer Community](https://trailblazers.salesforce.com/)

---

⭐ **Se este projeto foi útil, considere dar uma estrela!** ⭐

---

**Desenvolvido com ❤️ usando Salesforce Platform**
