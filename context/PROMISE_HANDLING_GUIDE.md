# Guia de Orientação: Resolvendo Problemas com Promises em LWC

## Introdução

Este guia tem como objetivo orientar a depuração e resolução de problemas relacionados a `Promises` no projeto. Uma `Promise` em JavaScript é um objeto que representa a eventual conclusão (ou falha) de uma operação assíncrona. Em LWC, quase toda interação com o servidor (chamadas Apex) retorna uma `Promise`.

Um problema comum é uma "rejeição de promise não tratada" (*unhandled promise rejection*). Isso acontece quando uma operação assíncrona falha (por exemplo, um erro em uma classe Apex) e não há um código para "capturar" essa falha. O resultado é que o componente pode parar de funcionar, não carregar dados ou simplesmente falhar silenciosamente, sem dar nenhuma indicação do problema ao usuário.

## Como Identificar o Problema

O problema geralmente se manifesta em chamadas a métodos Apex que não possuem um bloco `.catch()` para tratar falhas.

**Exemplo do problema encontrado em `cinemaBooking/cinemaBooking.js`:**

```javascript
// force-app/main/default/lwc/cinemaBooking/cinemaBooking.js

loadShowtimes() {
    // ...
    getAvailableShowtimes({ 
        movieId: this.selectedMovie.Id,
        selectedDate: dateObj
    })
    .then(result => {
        this.showtimes = result;
    })
    .catch(error => {
        // O erro é apenas logado no console, o usuário não vê nada.
        console.error('Error loading showtimes:', error);
    });
}
```

No código acima, se a chamada `getAvailableShowtimes` falhar, o erro será impresso no console do navegador, mas o usuário final não receberá nenhum feedback. A lista de horários simplesmente ficará vazia, dando a impressão de que não há horários disponíveis.

## Como Resolver o Problema

A solução é sempre fornecer um feedback claro ao usuário quando uma operação assíncrona falha. Em LWC, a melhor maneira de fazer isso é usando o `ShowToastEvent`.

**Passo a passo para a correção:**

1.  **Importe o `ShowToastEvent`**: No início do seu arquivo `.js`, adicione a importação.
2.  **Adicione o tratamento de erro no `.catch()`**: No bloco `.catch()`, dispare um evento de toast para exibir o erro.

**Aplicando a correção em `cinemaBooking/cinemaBooking.js`:**

Primeiro, importe o `ShowToastEvent` no topo do arquivo:

```javascript
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
```

Depois, modifique o método `loadShowtimes` para exibir um toast em caso de erro:

```javascript
// force-app/main/default/lwc/cinemaBooking/cinemaBooking.js

loadShowtimes() {
    if (!this.selectedMovie || !this.selectedMovie.Id) {
        console.error('No movie selected');
        return;
    }
    const dateObj = new Date(this.selectedDate);
    getAvailableShowtimes({ 
        movieId: this.selectedMovie.Id,
        selectedDate: dateObj
    })
    .then(result => {
        this.showtimes = result;
    })
    .catch(error => {
        console.error('Error loading showtimes:', error);
        // Adicione o feedback para o usuário aqui
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Erro ao Carregar os Horários',
                message: error.body ? error.body.message : 'Ocorreu um erro desconhecido.',
                variant: 'error',
                mode: 'sticky'
            })
        );
    });
}
```

## Melhores Práticas para Promises em LWC

1.  **Sempre use `.catch()` ou `try/catch`**: Para toda chamada Apex imperativa, certifique-se de ter um bloco `.catch()` ou, se estiver usando `async/await`, um bloco `try/catch`.

    *   **Com `.then()`:**
        ```javascript
        myApexMethod()
            .then(result => { /* sucesso */ })
            .catch(error => { /* tratamento de erro */ });
        ```

    *   **Com `async/await`:**
        ```javascript
        async myAsyncMethod() {
            try {
                let result = await myApexMethod();
                /* sucesso */
            } catch (error) {
                /* tratamento de erro */
            }
        }
        ```

2.  **Forneça Feedback ao Usuário**: Não confie apenas no `console.log` ou `console.error`. Use `ShowToastEvent` para notificar o usuário sobre o que aconteceu. Isso melhora drasticamente a experiência do usuário.

3.  **Seja Específico nas Mensagens de Erro**: Em vez de uma mensagem genérica como "Erro", tente extrair a mensagem de erro real do objeto de erro do Apex: `error.body.message`.

Seguindo estas diretrizes, você pode garantir que seu aplicativo seja mais robusto e fácil de usar, mesmo quando as coisas dão errado nos bastidores.
