#!/bin/bash

# Script para gestionar contenedores Docker de bases de datos
# Uso: ./manage-databases.sh {mysql|kafka|cassandra|postgresql} {start|stop|status}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el uso
show_usage() {
    echo -e "${BLUE}Uso:${NC} $0 {mysql|kafka|cassandra|postgresql|all} {start|stop|status|restart}"
    echo ""
    echo -e "${BLUE}Servicios disponibles:${NC}"
    echo "  mysql       - MySQL 8.0 (Puerto 3306)"
    echo "  kafka       - Kafka + Kafka UI (Puertos 9092, 29092, 9090)"
    echo "  cassandra   - Cassandra 4.1 (Puerto 9042)"
    echo "  postgresql  - PostgreSQL 15 (Puerto 5432)"
    echo "  all         - Todos los servicios"
    echo ""
    echo -e "${BLUE}Comandos:${NC}"
    echo "  start       - Iniciar el servicio"
    echo "  stop        - Detener el servicio"
    echo "  status      - Ver estado del servicio"
    echo "  restart     - Reiniciar el servicio"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 mysql start"
    echo "  $0 kafka status"
    echo "  $0 all stop"
    echo ""
    echo -e "${YELLOW}Nota:${NC} El script usa sudo automáticamente para los comandos de Docker"
}

# Función para iniciar un servicio
start_service() {
    local service=$1
    local compose_file="docker-compose-${service}.yml"

    echo -e "${BLUE}Iniciando ${service}...${NC}"
    sudo docker-compose -f "$compose_file" up -d

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${service} iniciado correctamente${NC}"

        # Mostrar información adicional para Kafka UI
        if [ "$service" == "kafka" ]; then
            echo ""
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Kafka UI disponible en:${NC} ${BLUE}http://localhost:9090${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
        fi
    else
        echo -e "${RED}✗ Error al iniciar ${service}${NC}"
        return 1
    fi
}

# Función para detener un servicio
stop_service() {
    local service=$1
    local compose_file="docker-compose-${service}.yml"

    echo -e "${BLUE}Deteniendo ${service}...${NC}"
    sudo docker-compose -f "$compose_file" down

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${service} detenido correctamente${NC}"
    else
        echo -e "${RED}✗ Error al detener ${service}${NC}"
        return 1
    fi
}

# Función para ver el estado de un servicio
status_service() {
    local service=$1
    local compose_file="docker-compose-${service}.yml"

    echo -e "${BLUE}Estado de ${service}:${NC}"
    sudo docker-compose -f "$compose_file" ps

    # Información adicional para Kafka UI
    if [ "$service" == "kafka" ]; then
        local kafka_ui_running=$(sudo docker-compose -f "$compose_file" ps | grep kafka-ui | grep "Up")
        if [ ! -z "$kafka_ui_running" ]; then
            echo ""
            echo -e "${GREEN}Kafka UI disponible en:${NC} ${BLUE}http://localhost:9090${NC}"
        fi
    fi
}

# Función para reiniciar un servicio
restart_service() {
    local service=$1
    echo -e "${BLUE}Reiniciando ${service}...${NC}"
    stop_service "$service"
    sleep 2
    start_service "$service"
}

# Validar número de argumentos
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

SERVICE=$1
COMMAND=$2

# Validar servicio
case $SERVICE in
    mysql|kafka|cassandra|postgresql)
        ;;
    all)
        ;;
    *)
        echo -e "${RED}Error: Servicio desconocido '$SERVICE'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

# Validar comando
case $COMMAND in
    start|stop|status|restart)
        ;;
    *)
        echo -e "${RED}Error: Comando desconocido '$COMMAND'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

# Ejecutar comando
if [ "$SERVICE" == "all" ]; then
    # Ejecutar comando para todos los servicios
    for svc in mysql kafka cassandra postgresql; do
        echo ""
        case $COMMAND in
            start)
                start_service "$svc"
                ;;
            stop)
                stop_service "$svc"
                ;;
            status)
                status_service "$svc"
                ;;
            restart)
                restart_service "$svc"
                ;;
        esac
    done
else
    # Ejecutar comando para un servicio específico
    case $COMMAND in
        start)
            start_service "$SERVICE"
            ;;
        stop)
            stop_service "$SERVICE"
            ;;
        status)
            status_service "$SERVICE"
            ;;
        restart)
            restart_service "$SERVICE"
            ;;
    esac
fi

exit 0
