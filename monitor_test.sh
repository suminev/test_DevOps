#!/bin/bash

PROCESS_NAME="test"
MONITORING_URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"

# Проверяем, запущен ли процесс
is_process_running() {
    pgrep -x "$PROCESS_NAME" >/dev/null
}

# Отправляем запрос к серверу мониторинга
ping_monitoring_server() {
    curl -s -m 10 -o /dev/null -w "%{http_code}" "$MONITORING_URL"
}

# Логируем сообщение
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Основная логика
main() {
    if is_process_running; then
        # Проверяем, был ли процесс перезапущен (сравниваем текущий PID с предыдущим)
        CURRENT_PID=$(pgrep -x "$PROCESS_NAME")

        if [[ -f "/var/tmp/${PROCESS_NAME}_pid" ]]; then
            PREVIOUS_PID=$(cat "/var/tmp/${PROCESS_NAME}_pid")

            if [[ "$CURRENT_PID" != "$PREVIOUS_PID" ]]; then
                log_message "Процесс $PROCESS_NAME был перезапущен (предыдущий PID: $PREVIOUS_PID, текущий PID: $CURRENT_PID)"
            fi
        fi

        echo "$CURRENT_PID" > "/var/tmp/${PROCESS_NAME}_pid"

        # Пингуем сервер мониторинга
        response_code=$(ping_monitoring_server)

        if [[ "$response_code" != "200" ]]; then
            log_message "Сервер мониторинга не доступен (HTTP-код ответа: $response_code)"
        fi
    fi
}

main
