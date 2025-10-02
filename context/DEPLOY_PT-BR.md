# 🚀 Guia de Deploy - SF-SeatTracker

## ⚠️ Pré-requisitos

Certifique-se de ter instalado o **Salesforce CLI v2** (`sf`):

```bash
# Verificar se tem o SF CLI instalado
sf --version

# Se não tiver, instale em: https://developer.salesforce.com/tools/salesforcecli
```

---

## Passo 1: Autenticar na Org Salesforce

Abra o terminal na pasta do projeto e execute:

```bash
# Autenticar na org de desenvolvimento
sf org login web --alias DevOrg --instance-url https://login.salesforce.com
```

Isso abrirá uma janela do navegador. Faça login com suas credenciais Salesforce.

---

## Passo 2: Verificar Conexão

```bash
# Verificar se está conectado
sf org display --target-org DevOrg

# Listar todas as orgs conectadas
sf org list
```

---

## Passo 3: Deploy dos Metadados

### Opção A: Deploy Completo (Recomendado)

```bash
# Deploy de todos os metadados
sf project deploy start --source-dir force-app/main/default --target-org DevOrg
```

### Opção B: Validar antes de Deployar

```bash
# Validar sem fazer deploy (teste)
sf project deploy start --source-dir force-app/main/default --dry-run --target-org DevOrg

# Se a validação passou, faça o deploy real
sf project deploy start --source-dir force-app/main/default --target-org DevOrg
```

### Opção C: Deploy por Partes (Se houver erro)

```bash
# 1. Deploy dos objetos primeiro
sf project deploy start --source-dir force-app/main/default/objects --target-org DevOrg

# 2. Deploy das classes Apex
sf project deploy start --source-dir force-app/main/default/classes --target-org DevOrg

# 3. Deploy dos triggers
sf project deploy start --source-dir force-app/main/default/triggers --target-org DevOrg

# 4. Deploy dos LWC
sf project deploy start --source-dir force-app/main/default/lwc --target-org DevOrg

# 5. Deploy das tabs e aplicação
sf project deploy start --source-dir force-app/main/default/tabs --target-org DevOrg
sf project deploy start --source-dir force-app/main/default/applications --target-org DevOrg

# 6. Deploy das permissões
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org DevOrg

# 7. Deploy das configurações
sf project deploy start --source-dir force-app/main/default/remoteSiteSettings --target-org DevOrg
```

**Tempo estimado de deploy:** 3-5 minutos

---

## Passo 4: Atribuir Permission Set

```bash
# Atribuir permissões ao seu usuário
sf org assign permset --name Cinema_Reservation_Admin --target-org DevOrg
```

---

## Passo 5: Importar Dados de Exemplo (Opcional)

```bash
# Importar 3 filmes, 2 cinemas e 3 sessões
sf data import tree --plan data/sample-data-plan.json --target-org DevOrg
```

Isso criará:
- 3 Filmes (The Matrix, Spider-Man, Dune)
- 2 Cinemas em São Paulo
- 3 Sessões
- 300 Assentos (gerados automaticamente via trigger)

---

## Passo 6: Executar Testes (Opcional mas Recomendado)

```bash
# Executar todos os testes Apex
sf apex run test --test-level RunLocalTests --wait 10 --result-format human --target-org DevOrg

# Ver cobertura de código
sf apex run test --code-coverage --result-format human --target-org DevOrg
```

Esperado: >75% de cobertura, todos os testes passando ✅

---

## Passo 7: Configurar Named Credential (Manual)

⚠️ **IMPORTANTE:** Named Credentials contêm dados sensíveis e devem ser configurados manualmente.

1. Abra sua org:
```bash
sf org open --target-org DevOrg
```

2. Vá para **Setup** (Configuração) > **Named Credentials**

3. Clique em **New Named Credential**

4. Preencha:
   - **Label:** `MovieGlu API`
   - **Name:** `MovieGlu_API`
   - **URL:** `https://api-gate.movieglu.com`
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** Custom

5. Em **Custom Headers**, adicione:
   ```
   x-api-key: SUA_CHAVE_API_AQUI
   client: SEU_CLIENT_ID_AQUI
   authorization: Basic SEU_BASE64_CREDENTIALS_AQUI
   ```

6. Clique em **Save**

> **Nota:** Para obter credenciais da API MovieGlu, registre-se em: https://developer.movieglu.com

---

## Passo 8: Abrir a Org e Testar

```bash
# Abrir a org no navegador
sf org open --target-org DevOrg
```

### Testando a Aplicação:

1. Clique no **App Launcher** (9 pontos no canto superior esquerdo)
2. Procure e abra **Cinema Management**
3. Você verá as tabs: Movies, Theaters, Showtimes, Reservations

### Adicionando o Componente LWC:

**Opção A: Usar o componente principal (cinemaBooking)**

1. No App Launcher, clique em **Home**
2. Clique na engrenagem ⚙️ > **Edit Page**
3. Arraste o componente **cinemaBooking** para a página
4. Clique em **Save** > **Activate** > **Assign as Org Default**

**Opção B: Criar uma Tab customizada**

1. Setup > **Tabs** > **Lightning Component Tabs**
2. New > Selecione **c:cinemaBooking**
3. Label: "Book Tickets"
4. Adicione ao app Cinema Management

---

## 🎯 Fluxo de Teste Completo

### Teste 1: Visualizar Dados
1. Vá para **Movies** tab
2. Verifique se há 3 filmes (se importou sample data)
3. Abra um filme e veja os detalhes

### Teste 2: Verificar Geração Automática de Assentos
1. Vá para **Showtimes** tab
2. Abra uma sessão
3. Vá para **Related** > **Seats**
4. Verifique se há 100 assentos (A-1 até J-10) ✅

### Teste 3: Criar Reserva Manual
1. Vá para **Reservations** tab
2. Clique em **New**
3. Preencha:
   - Customer Name: "João Silva"
   - Customer Email: "joao@example.com"
   - Showtime: Selecione uma sessão
   - Number of Seats: 2
4. Save

### Teste 4: Testar LWC (Se adicionou à página)
1. Vá para a página com o componente **cinemaBooking**
2. **Passo 1:** Selecione um filme
3. **Passo 2:** Escolha data e horário
4. **Passo 3:** Selecione assentos no grid interativo
5. **Passo 4:** Preencha dados e confirme
6. Verifique se recebeu email de confirmação ✅

### Teste 5: Sincronizar com API (Opcional - requer API key)
Execute no Developer Console:
```apex
// Sincronizar filmes da API MovieGlu
MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');

// Sincronizar cinemas próximos
MovieGluService.syncNearbyTheaters('-23.5505', '-46.6333', 10);
```

---

## 📊 Scripts NPM Atualizados

Atualize os scripts no `package.json` para usar `sf`:

```json
{
  "scripts": {
    "deploy": "sf project deploy start --source-dir force-app/main/default",
    "deploy:check": "sf project deploy start --source-dir force-app/main/default --dry-run",
    "test:apex": "sf apex run test --test-level RunLocalTests --wait 10 --result-format human",
    "open:org": "sf org open",
    "assign:permset": "sf org assign permset --name Cinema_Reservation_Admin",
    "import:data": "sf data import tree --plan data/sample-data-plan.json"
  }
}
```

Depois use:

```bash
# Deploy
npm run deploy

# Validar antes de deployar
npm run deploy:check

# Abrir org
npm run open:org

# Executar testes
npm run test:apex

# Atribuir permissão
npm run assign:permset

# Importar dados
npm run import:data
```

---

## ⚠️ Troubleshooting

### Erro: "Insufficient Privileges"
**Solução:**
```bash
sf org assign permset --name Cinema_Reservation_Admin --target-org DevOrg
```

### Erro: "Remote Site Not Allowed"
**Solução:**
1. Setup > Remote Site Settings
2. Verifique se `MovieGlu_API` está **Active**

### Erro: "Component Not Found"
**Solução:**
```bash
# Limpar cache e re-deployar
sf project deploy start --source-dir force-app/main/default/lwc --target-org DevOrg
```

### Erro: "Invalid Cross Reference Key"
**Solução:** Deploy objetos antes das classes:
```bash
sf project deploy start --source-dir force-app/main/default/objects --target-org DevOrg
sf project deploy start --source-dir force-app/main/default/classes --target-org DevOrg
```

### Testes Falhando
**Solução:**
```bash
# Ver logs detalhados
sf apex run test --tests MovieGluServiceTest --result-format human --target-org DevOrg

# Ver logs em tempo real
sf apex tail log --target-org DevOrg
```

### Verificar Status do Deploy
```bash
# Ver histórico de deploys
sf project deploy report

# Cancelar deploy em andamento
sf project deploy cancel --job-id 0Af...
```

---

## 🔄 Deploy para Produção

### 1. Deploy Validado (Recomendado)
```bash
# 1. Validar em produção
sf project deploy start --source-dir force-app/main/default --dry-run --test-level RunLocalTests --wait 30 --target-org ProdOrg

# 2. Se validação passou, fazer deploy quick usando o validation ID
sf project deploy quick --job-id 0Af... --target-org ProdOrg
```

### 2. Deploy Direto (Com cuidado!)
```bash
# Deploy direto em produção
sf project deploy start --source-dir force-app/main/default --test-level RunLocalTests --target-org ProdOrg
```

### 3. Criar Package (Recomendado para empresas)
```bash
# Criar unlocked package
sf package create --name "SF-SeatTracker" --package-type Unlocked --path force-app

# Criar versão
sf package version create --package "SF-SeatTracker" --wait 10

# Instalar em produção
sf package install --package 04t... --target-org ProdOrg
```

---

## 📝 Checklist de Deploy

Antes de considerar o deploy completo:

- [ ] SF CLI v2 instalado (`sf --version`)
- [ ] Autenticado na org (`sf org list`)
- [ ] Deploy de metadados concluído
- [ ] Permission set atribuído
- [ ] Dados de exemplo importados
- [ ] Testes Apex passando (>75%)
- [ ] Named Credential configurado
- [ ] Remote Site Settings ativo
- [ ] Componente LWC adicionado à página
- [ ] Teste manual de reserva realizado
- [ ] Email de confirmação recebido
- [ ] Assentos sendo gerados automaticamente

---

## 🆕 Comandos Úteis do SF CLI v2

### Gestão de Orgs
```bash
# Listar orgs
sf org list

# Definir org padrão
sf config set target-org=DevOrg

# Logout de uma org
sf org logout --target-org DevOrg

# Abrir org
sf org open --target-org DevOrg
```

### Deploy e Retrieve
```bash
# Deploy com teste
sf project deploy start --source-dir force-app --test-level RunLocalTests

# Retrieve metadata da org
sf project retrieve start --source-dir force-app --target-org DevOrg

# Ver status do deploy
sf project deploy report

# Cancelar deploy
sf project deploy cancel
```

### Apex e Testes
```bash
# Executar código Apex anônimo
sf apex run --file script.apex

# Executar teste específico
sf apex run test --tests MovieGluServiceTest

# Ver logs
sf apex tail log

# Obter logs de debug
sf apex get log --log-id 07L...
```

### Dados
```bash
# Importar dados
sf data import tree --plan data/plan.json

# Exportar dados
sf data export tree --query "SELECT Id, Name FROM Movie__c" --output-dir data

# Query SOQL
sf data query --query "SELECT Id, Name FROM Movie__c" --target-org DevOrg
```

### Scratch Orgs (Para desenvolvimento)
```bash
# Criar scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias ScratchOrg --duration-days 30

# Push código para scratch org
sf project deploy start --source-dir force-app --target-org ScratchOrg

# Atribuir permissão
sf org assign permset --name Cinema_Reservation_Admin --target-org ScratchOrg

# Deletar scratch org
sf org delete scratch --target-org ScratchOrg
```

---

## 🔧 Migração de sfdx para sf

Se você tem scripts antigos com `sfdx`, aqui está a conversão:

| Comando Antigo (sfdx) | Comando Novo (sf) |
|----------------------|-------------------|
| `sfdx auth:web:login` | `sf org login web` |
| `sfdx force:org:display` | `sf org display` |
| `sfdx force:org:list` | `sf org list` |
| `sfdx force:source:deploy` | `sf project deploy start` |
| `sfdx force:source:push` | `sf project deploy start` |
| `sfdx force:source:pull` | `sf project retrieve start` |
| `sfdx force:apex:test:run` | `sf apex run test` |
| `sfdx force:apex:log:tail` | `sf apex tail log` |
| `sfdx force:user:permset:assign` | `sf org assign permset` |
| `sfdx force:data:tree:import` | `sf data import tree` |
| `sfdx force:org:open` | `sf org open` |
| `sfdx force:org:create` | `sf org create scratch` |

---

## 🎉 Deploy Bem Sucedido!

Se todos os passos foram concluídos com sucesso, você agora tem:

✅ Sistema completo de reserva de cinema  
✅ 5 objetos customizados com 66 campos  
✅ 10 classes Apex com >75% cobertura  
✅ 5 componentes LWC interativos  
✅ Geração automática de assentos  
✅ Envio de emails de confirmação  
✅ Interface moderna e responsiva  

**Parabéns! Seu SF-SeatTracker está no ar! 🎬🍿**

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs: `sf apex tail log --target-org DevOrg`
2. Consulte a documentação oficial: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/
3. Revise o IMPLEMENTATION_SUMMARY.md
4. Abra um issue no GitHub

---

## 📚 Recursos Adicionais

- **Documentação SF CLI v2:** https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/
- **Guia de Migração sfdx → sf:** https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_sf_intro.htm
- **Salesforce DX Developer Guide:** https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/
- **LWC Developer Guide:** https://developer.salesforce.com/docs/component-library/documentation/en/lwc

---

**Desenvolvido com ❤️ usando Salesforce Platform**  
**Atualizado para Salesforce CLI v2 (sf)**
