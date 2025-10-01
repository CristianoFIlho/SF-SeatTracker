# 🚀 Comandos Corretos para Deploy - SF CLI v2

## ⚠️ IMPORTANTE: Flags Corretas

Use `-o` ou `--target-org` (NÃO use apenas `--target`)

---

## 🔑 Passo 1: Login

```bash
sf org login web --alias DevOrg
```

Ou para sandbox:
```bash
sf org login web --alias DevOrg --instance-url https://test.salesforce.com
```

---

## 📦 Passo 2: Deploy

### Opção A: Deploy Completo (Simplificado)
```bash
sf project deploy start -d force-app/main/default -o DevOrg
```

### Opção B: Deploy Completo (Com nome completo da flag)
```bash
sf project deploy start --source-dir force-app/main/default --target-org DevOrg
```

### Opção C: Deploy Sem Especificar Org (Usa org padrão)
```bash
# Definir org padrão primeiro
sf config set target-org=DevOrg

# Depois pode deployar sem especificar
sf project deploy start -d force-app/main/default
```

---

## 👤 Passo 3: Atribuir Permissões

```bash
sf org assign permset -n Cinema_Reservation_Admin -o DevOrg
```

Ou sem especificar org (se já definiu como padrão):
```bash
sf org assign permset -n Cinema_Reservation_Admin
```

---

## 📊 Passo 4: Importar Dados

```bash
sf data import tree -f data/sample-data-plan.json -o DevOrg
```

Ou:
```bash
sf data import tree --plan data/sample-data-plan.json --target-org DevOrg
```

---

## 🌐 Passo 5: Abrir Org

```bash
sf org open -o DevOrg
```

Ou sem especificar:
```bash
sf org open
```

---

## 🧪 Passo 6: Executar Testes

```bash
sf apex run test -l RunLocalTests -o DevOrg -w 10
```

Forma completa:
```bash
sf apex run test --test-level RunLocalTests --target-org DevOrg --wait 10 --result-format human
```

---

## 📋 Resumo das Flags (Forma Curta vs Longa)

| Flag Curta | Flag Longa | Uso |
|-----------|-----------|-----|
| `-o` | `--target-org` | Especificar org alvo |
| `-d` | `--source-dir` | Diretório fonte |
| `-n` | `--name` | Nome (permset, etc) |
| `-f` | `--file` ou `--plan` | Arquivo |
| `-l` | `--test-level` | Nível de teste |
| `-w` | `--wait` | Tempo de espera |

---

## ✅ Sequência Completa de Deploy (COPIE E COLE)

```bash
# 1. Login
sf org login web --alias DevOrg

# 2. Verificar conexão
sf org list

# 3. Deploy
sf project deploy start -d force-app/main/default -o DevOrg

# 4. Atribuir permissão
sf org assign permset -n Cinema_Reservation_Admin -o DevOrg

# 5. Importar dados
sf data import tree -f data/sample-data-plan.json -o DevOrg

# 6. Abrir org
sf org open -o DevOrg
```

---

## 🔧 Alternativa: Usar Org Padrão (Mais Simples)

```bash
# 1. Login
sf org login web --alias DevOrg --set-default

# 2. Agora não precisa especificar -o em cada comando
sf project deploy start -d force-app/main/default

# 3. Atribuir permissão
sf org assign permset -n Cinema_Reservation_Admin

# 4. Importar dados
sf data import tree -f data/sample-data-plan.json

# 5. Abrir org
sf org open
```

---

## 📝 Deploy Por Partes (Se der erro)

```bash
# Objetos
sf project deploy start -d force-app/main/default/objects -o DevOrg

# Classes
sf project deploy start -d force-app/main/default/classes -o DevOrg

# Triggers
sf project deploy start -d force-app/main/default/triggers -o DevOrg

# LWC
sf project deploy start -d force-app/main/default/lwc -o DevOrg

# Tabs
sf project deploy start -d force-app/main/default/tabs -o DevOrg

# Aplicação
sf project deploy start -d force-app/main/default/applications -o DevOrg

# Permissionsets
sf project deploy start -d force-app/main/default/permissionsets -o DevOrg

# Remote Site Settings
sf project deploy start -d force-app/main/default/remoteSiteSettings -o DevOrg
```

---

## ⚡ Comandos Úteis

```bash
# Ver orgs conectadas
sf org list

# Ver detalhes da org
sf org display -o DevOrg

# Definir org padrão
sf config set target-org=DevOrg

# Ver org padrão atual
sf config get target-org

# Logout
sf org logout -o DevOrg

# Ver logs em tempo real
sf apex tail log -o DevOrg

# Executar teste específico
sf apex run test -n MovieGluServiceTest -o DevOrg

# Query SOQL
sf data query -q "SELECT Id, Name FROM Movie__c" -o DevOrg

# Ver status do deploy
sf project deploy report

# Cancelar deploy
sf project deploy cancel
```

---

## 🆘 Troubleshooting

### Erro: "Nonexistent flag: --target"
**Problema:** Usando `--target` ao invés de `--target-org`  
**Solução:** Use `-o` ou `--target-org`

```bash
# ❌ ERRADO
sf org open --target DevOrg

# ✅ CERTO
sf org open -o DevOrg
# ou
sf org open --target-org DevOrg
```

### Erro: "No default org found"
**Solução:** Defina uma org padrão ou especifique com `-o`

```bash
# Definir padrão
sf config set target-org=DevOrg

# Ou sempre use -o
sf org open -o DevOrg
```

### Erro: "No org configuration found"
**Solução:** Fazer login novamente

```bash
sf org login web --alias DevOrg
```

---

## 📖 Ajuda dos Comandos

```bash
# Ajuda geral
sf --help

# Ajuda de um comando específico
sf project deploy start --help
sf org login --help
sf apex run test --help
```

---

## 🎯 Quick Start - 5 Comandos

```bash
sf org login web --alias DevOrg --set-default
sf project deploy start -d force-app/main/default
sf org assign permset -n Cinema_Reservation_Admin
sf data import tree -f data/sample-data-plan.json
sf org open
```

Pronto! 🎬

