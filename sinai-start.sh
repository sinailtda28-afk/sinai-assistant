#!/bin/bash
# sinai-start.sh - Inicia Rails + tunel + webhook Telegram
# Uso: ./sinai-start.sh

RAILS_DIR="/mnt/c/Users/USUARIO/Documents/CLAUDE/productivity-assistant"
LOG="/tmp/sinai-start.log"
BOT_TOKEN="8646373366:AAFak_TTwsW6-_HPUIgYt4XVNYBePpwVWWA"
PORT=3001

echo "=== Sinai Assistant - $(date) ===" | tee -a $LOG

# Matar processos anteriores
pkill -f "rails server" 2>/dev/null
pkill -f "localhost.run" 2>/dev/null
sleep 2

# Iniciar Rails
cd "$RAILS_DIR"
export TELEGRAM_BOT_TOKEN="$BOT_TOKEN"
echo "Iniciando Rails na porta $PORT..." | tee -a $LOG
nohup ./bin/rails server -p $PORT -b 0.0.0.0 > /tmp/rails_$PORT.log 2>&1 &
RAILS_PID=$!
echo "Rails PID: $RAILS_PID" | tee -a $LOG

# Aguardar Rails boot (pode demorar ~90s)
echo "Aguardando Rails iniciar..." | tee -a $LOG
for i in $(seq 1 20); do
  sleep 10
  if curl -s -o /dev/null http://localhost:$PORT/ 2>/dev/null; then
    echo "Rails OK apos $((i*10))s" | tee -a $LOG
    break
  fi
  echo "  Aguardando... $((i*10))s" | tee -a $LOG
done

# Iniciar tunel
echo "Iniciando tunel localhost.run..." | tee -a $LOG
nohup ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o TCPKeepAlive=yes -R 80:localhost:$PORT nokey@localhost.run > /tmp/tunnel.log 2>&1 &
TUNNEL_PID=$!
echo "Tunnel PID: $TUNNEL_PID" | tee -a $LOG

# Aguardar URL do tunel
sleep 12
URL=$(grep -oP 'https://[a-z0-9]+\.lhr\.life' /tmp/tunnel.log | tail -1)

if [ -z "$URL" ]; then
  echo "ERRO: Nao foi possivel obter URL do tunel" | tee -a $LOG
  exit 1
fi

echo "URL publica: $URL" | tee -a $LOG

# Salvar URL na area de trabalho para acesso facil
echo "$URL" > "/mnt/c/Users/USUARIO/Desktop/Sinai - URL.txt"

# Configurar webhook Telegram
echo "Configurando webhook Telegram..." | tee -a $LOG
WEBHOOK_RESULT=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/setWebhook?url=$URL/telegram/webhook")
echo "Webhook: $WEBHOOK_RESULT" | tee -a $LOG

echo "" | tee -a $LOG
echo "=== PRONTO ===" | tee -a $LOG
echo "Site: $URL" | tee -a $LOG
echo "Bot Telegram: @Gfueb_bot" | tee -a $LOG
echo "" | tee -a $LOG
echo "Para parar: pkill -f 'rails server'; pkill -f 'localhost.run'" | tee -a $LOG
