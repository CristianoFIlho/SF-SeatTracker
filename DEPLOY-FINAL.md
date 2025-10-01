# 🚀 Deploy Final - SF-SeatTracker

## ✅ Comandos Corretos (SF CLI v2)

### **Sequência Completa de Deploy:**

```bash
# 1. Login
sf org login web --alias DevOrg --set-default

# 2. Deploy
sf project deploy start -d force-app/main/default

# 3. Atribuir permissão
sf org assign permset -n Cinema_Reservation_Admin

# 4. Importar dados (COMANDO CORRETO!)
sf data import tree --plan data/sample-data-plan.json

# 5. Abrir org
sf org open
```

---

## ⚠️ IMPORTANTE: Flag Correta para Import

**❌ ERRADO:**
```bash
sf data import tree -f data/sample-data-plan.json
# Erro: References only supported with --plan
```

**✅ CORRETO:**
```bash
sf data import tree --plan data/sample-data-plan.json
```

**Por quê?**  
Quando o arquivo JSON contém **referências** (como `@MovieRef1`, `@TheaterRef1`), você DEVE usar `--plan`.

---

## 📋 Scripts NPM Atualizados

```bash
# Login
npm run login

# Deploy
npm run deploy

# Permissões
npm run assign:permset

# Dados (agora com --plan correto)
npm run import:data

# Abrir
npm run open:org
```

---

## 🧪 Verificar Deploy

```bash
# Ver se deployou tudo
sf org display

# Executar testes
sf apex run test -l RunLocalTests -w 10

# Ver objetos criados
sf data query -q "SELECT COUNT() FROM Movie__c"
sf data query -q "SELECT COUNT() FROM Theater__c"
sf data query -q "SELECT COUNT() FROM Showtime__c"
```

Esperado após importar dados:
- 3 Movies
- 2 Theaters
- 3 Showtimes
- 300 Seats (gerados automaticamente)

---

## 🎯 Testar na UI

1. **App Launcher** → **Cinema Management**
2. Clique em **Movies** → Você deve ver 3 filmes
3. Clique em **Showtimes** → Abra uma sessão
4. Vá em **Related** → **Seats** → Deve ter 100 assentos

---

## 🎬 Adicionar Componente LWC

1. **Home** → Clique na engrenagem ⚙️ → **Edit Page**
2. Arraste **cinemaBooking** para a página
3. **Save** → **Activate**
4. Teste o fluxo de reserva!

---

## ✅ Checklist Final

- [ ] Login concluído
- [ ] Deploy sem erros
- [ ] Permission set atribuído
- [ ] Dados importados (3 movies, 2 theaters, 3 showtimes)
- [ ] Cinema Management app acessível
- [ ] Testes passando (>75%)
- [ ] Componente LWC adicionado à página
- [ ] Fluxo de reserva testado

---

## 🎉 Pronto!

Seu **SF-SeatTracker** está deployado e funcionando! 🎬🍿

**Próximos passos:**
- Configure Named Credential para MovieGlu API
- Customize os preços e layouts
- Crie dashboards de analytics
- Publique em Experience Cloud

---

**Desenvolvido com ❤️ usando Salesforce Platform**

