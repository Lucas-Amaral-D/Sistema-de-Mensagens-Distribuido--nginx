# Sistema de Mensagens Distribuído (Replicação P2P e Nginx Load Balancing)

## Descrição do Projeto
Este projeto implementa um sistema de mensagens distribuído e altamente disponível utilizando Docker e Docker Compose.  
A arquitetura conta com três réplicas da aplicação Flask (Python) para armazenamento de mensagens e um Nginx atuando como Load Balancer e Proxy Reverso.  

O ponto central da solução é garantir a consistência de dados através de um mecanismo de Replicação P2P (Peer-to-Peer): sempre que uma réplica recebe uma mensagem (via Load Balancer), ela imediatamente replica essa mensagem para as demais réplicas do sistema, garantindo que todas possuam o mesmo conjunto de dados.  

---

## Arquitetura e Funcionalidades

| Componente | Função | Tecnologia |
|------------|--------|------------|
| g1-nginx   | Balanceamento de Carga e Proxy Reverso para os serviços app1, app2 e app3. Utiliza a estratégia Round Robin por padrão. | Nginx |
| app1, app2, app3 | Réplicas da aplicação de mensagens. Armazenam os dados em volumes persistentes e executam a Replicação P2P. | Flask (Python) |
| Volumes Docker | Garantem a persistência dos dados mesmo após a reinicialização dos containers. | Docker |
| Rede Docker | Permite que o Nginx e as aplicações se comuniquem internamente de forma transparente. | Docker Compose |

### Fluxo de Comunicação
1. O usuário envia uma requisição POST para o Nginx (`http://localhost:8080/send`).  
2. O Nginx encaminha a requisição para uma das réplicas (ex: app1) usando Round Robin.  
3. A réplica (app1) salva a mensagem localmente e, em seguida, replica a mensagem para as outras réplicas (app2 e app3) usando seus endpoints internos.  
4. Todas as réplicas mantêm a mesma lista de mensagens, garantindo a Consistência de Dados.  

---

## Como Executar o Projeto

Certifique-se de ter o Docker e o Docker Compose instalados em seu ambiente.

### 1. Clonar o Repositório
```bash
git clone https://github.com/Lucas-Amaral-D/Sistema-de-Mensagens-Distribuido--nginx.git
cd Sistema-de-Mensagens-Distribuido--nginx
```

### 2. Subir o Ambiente
O `docker-compose.yml` construirá as imagens e iniciará os quatro serviços (`g1-nginx`, `app1`, `app2`, `app3`).

```bash
docker-compose up --build -d
```

A flag `-d` executa os containers em segundo plano (detached mode).  

### 3. Verificar Status
Confirme se todos os containers estão rodando:  

```bash
docker-compose ps
```

---

## Teste e Validação Automatizada

O script `test.sh` foi criado para provar automaticamente o Balanceamento de Carga e a Consistência de Dados do sistema.

### 1. Preparar e Executar o Teste

Dar permissão de execução ao script:  

```bash
chmod +x test.sh
```

Executar o script de teste:  

```bash
./test.sh
```

### 2. Análise da Saída
O script executa três requisições POST através do Load Balancer e, em seguida, verifica a contagem de mensagens em cada réplica:

- **Balanceamento de Carga:** A saída mostrará que cada mensagem foi direcionada para uma réplica diferente (Round Robin).  
- **Consistência de Dados:** O resultado final deve ser OK para todas as réplicas, comprovando que o total de mensagens é idêntico em App 1, App 2 e App 3.  

Exemplo de saída do teste:

```
=================================================
INICIANDO TESTE DO SISTEMA DISTRIBUÍDO G1
...
-> Contagem Final Esperada: [NÚMERO_DE_MENSAGENS]

4. TESTE DE BALANCEAMENTO DE CARGA E REPLICAÇÃO (ROUND ROBIN)
------------------------------------------------------------------
  [POST] Enviado: "MSG 1 - Teste de Balanceamento" -> Recebido por: appX
  [POST] Enviado: "MSG 2 - Teste de Balanceamento" -> Recebido por: appY
  [POST] Enviado: "MSG 3 - Teste de Balanceamento" -> Recebido por: appZ

5. VERIFICAÇÃO DE CONSISTÊNCIA DE DADOS
------------------------------------------------------------------
  [App 1 (5001)] Total de mensagens: 19 (OK - Esperado: 19)
  [App 2 (5002)] Total de mensagens: 19 (OK - Esperado: 19)
  [App 3 (5003)] Total de mensagens: 19 (OK - Esperado: 19)

=================================================
TESTE CONCLUÍDO. VERIFIQUE o status (OK/FALHA).
=================================================
```

---

## Remoção dos Containers (Opcional)

Para derrubar o ambiente e remover os containers e a rede Docker (mantendo os dados persistentes):  

```bash
docker-compose down
```

Para derrubar o ambiente e remover os volumes (dados persistentes), use a flag `-v`:  

```bash
docker-compose down -v
```
