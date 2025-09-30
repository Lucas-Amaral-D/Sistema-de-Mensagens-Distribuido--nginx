#!/bin/bash

LB_URL="http://localhost:8080/send"
APP1_URL="http://localhost:5001/messages"
APP2_URL="http://localhost:5002/messages"
APP3_URL="http://localhost:5003/messages"

send_message() {
    local message="$1"
    local response=$(curl -s --no-keepalive -X POST -H "Content-Type: application/json" -d "{\"message\":\"$message\"}" "$LB_URL")
    local app_received=$(echo "$response" | grep -o '"app":"[^"]*"' | cut -d: -f2 | tr -d '"')
    echo "  [POST] Enviado: \"$message\" -> Recebido por: $app_received"
}

check_messages() {
    local app_name="$1"
    local app_url="$2"
    local total_messages=$(curl -s "$app_url" | grep -o '"total_messages":[0-9]*' | cut -d: -f2)
    echo -n "  [$app_name] Total de mensagens: $total_messages"
    
    if [ "$total_messages" == "$EXPECTED_FINAL_COUNT" ]; then
        echo " (OK - Esperado: $EXPECTED_FINAL_COUNT)"
        return 0
    else
        echo " (FALHA - Esperado: $EXPECTED_FINAL_COUNT)"
        return 1
    fi
}

echo "================================================="
echo "INICIANDO TESTE DO SISTEMA DISTRIBUÍDO G1"
echo "================================================="

set -e

echo "1. Levantando containers via docker-compose..."
docker-compose up --build -d

echo "2. Aguardando serviços ficarem prontos (5s)..."
sleep 5

echo "3. Calculando contagem inicial de mensagens..."
INITIAL_COUNT=$(curl -s "$APP1_URL" | grep -o '"total_messages":[0-9]*' | cut -d: -f2)

if [ -z "$INITIAL_COUNT" ]; then
    INITIAL_COUNT=0
fi

MESSAGES_TO_SEND=3
EXPECTED_FINAL_COUNT=$((INITIAL_COUNT + MESSAGES_TO_SEND))

echo "   -> Contagem Inicial: ${INITIAL_COUNT}"
echo "   -> Mensagens a enviar: ${MESSAGES_TO_SEND}"
echo "   -> Contagem Final Esperada: ${EXPECTED_FINAL_COUNT}"

echo ""
echo "4. TESTE DE BALANCEAMENTO DE CARGA E REPLICAÇÃO (ROUND ROBIN)"
echo "------------------------------------------------------------------"

send_message "MSG 1 - Teste de Balanceamento"
send_message "MSG 2 - Teste de Balanceamento"
send_message "MSG 3 - Teste de Balanceamento"

echo ""
echo "5. VERIFICAÇÃO DE CONSISTÊNCIA DE DADOS"
echo "------------------------------------------------------------------"

check_messages "App 1 (5001)" "$APP1_URL"
check_messages "App 2 (5002)" "$APP2_URL"
check_messages "App 3 (5003)" "$APP3_URL"

echo ""
echo "================================================="
echo "TESTE CONCLUÍDO. VERIFIQUE o status (OK/FALHA)."
echo "================================================="
