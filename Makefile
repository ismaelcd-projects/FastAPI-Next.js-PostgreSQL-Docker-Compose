.PHONY: all up down build rebuild logs frontend-bash backend-bash db-bash clean clean-all health test-api scheduler-logs

# Nombre del archivo docker-compose.yml
COMPOSE_FILE = docker-compose.yaml

# Prefijo para los nombres de los servicios (opcional, Docker Compose usa el nombre del directorio por defecto)
# PROJECT_NAME = my_app_stack

all: up

# Levanta todos los servicios, construye las imágenes si es necesario
up:
	@echo "Levantando todos los servicios..."
	docker compose -f $(COMPOSE_FILE) up --build
	@echo "Servicios iniciados en segundo plano."
	@echo "Frontend: http://localhost:3000"
	@echo "Backend:  http://localhost:8000"
	@echo "API Docs: http://localhost:8000/docs"
	@echo "Adminer:  http://localhost:8080"

# Detiene y elimina todos los servicios, redes y volúmenes anónimos
down:
	@echo "Deteniendo y eliminando servicios..."
	docker compose -f $(COMPOSE_FILE) down

# Construye las imágenes sin iniciar los contenedores
build:
	@echo "Construyendo imágenes Docker..."
	docker compose -f $(COMPOSE_FILE) build --no-cache

# Reconstruye y levanta los servicios (equivalente a down y up --build)
rebuild: down build up

# Muestra los logs de todos los servicios. Usa 'make logs SERVICE_NAME=frontend' para un servicio específico.
logs:
	@echo "Mostrando logs..."
ifdef SERVICE_NAME
	docker compose -f $(COMPOSE_FILE) logs -f $(SERVICE_NAME)
else
	docker compose -f $(COMPOSE_FILE) logs -f
endif

# Ejecuta un bash shell dentro del contenedor del frontend
frontend-bash:
	@echo "Abriendo shell en el contenedor 'frontend'..."
	docker compose -f $(COMPOSE_FILE) exec frontend bash

# Ejecuta un bash shell dentro del contenedor del backend
backend-bash:
	@echo "Abriendo shell en el contenedor 'backend'..."
	docker compose -f $(COMPOSE_FILE) exec backend bash

# Ejecuta un bash shell dentro del contenedor de la base de datos (puedes usar 'psql -U user mydatabase' una vez dentro)
db-bash:
	@echo "Abriendo shell en el contenedor 'db'..."
	docker compose -f $(COMPOSE_FILE) exec db bash

# Limpia: detiene, elimina contenedores, redes y volúmenes con nombre (preserva imágenes)
clean: down
	@echo "🧹 Limpiando contenedores y volúmenes (preservando imágenes)..."
	docker compose -f $(COMPOSE_FILE) down --volumes
	docker container prune -f
	docker network prune -f
	@echo "✅ Limpieza completa (imágenes Docker preservadas)"

# Limpieza profunda: elimina también las imágenes
clean-all: down
	@echo "🧹 Limpieza profunda: eliminando contenedores, volúmenes e imágenes..."
	docker compose -f $(COMPOSE_FILE) down --volumes --rmi all
	docker system prune -a -f
	@echo "✅ Limpieza profunda completada"

# Verifica el estado de salud de los servicios
health:
	@echo "🔍 Verificando estado de salud de los servicios..."
	@echo "Frontend:"
	@curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend OK" || echo "❌ Frontend NO DISPONIBLE"
	@echo "Backend:"
	@curl -s http://localhost:8000/health > /dev/null && echo "✅ Backend OK" || echo "❌ Backend NO DISPONIBLE"
	@echo "Adminer:"
	@curl -s http://localhost:8080 > /dev/null && echo "✅ Adminer OK" || echo "❌ Adminer NO DISPONIBLE"

# Prueba los endpoints principales de la API
test-api:
	@echo "🧪 Probando endpoints de la API..."
	@echo "Health check:"
	@curl -s http://localhost:8000/health | jq '.' || echo "❌ Health check falló"
	@echo "API docs:"
	@curl -s http://localhost:8000/docs > /dev/null && echo "✅ API docs OK" || echo "❌ API docs NO DISPONIBLE"

# Muestra los logs del scheduler para verificar tareas programadas
scheduler-logs:
	@echo "📋 Mostrando logs del scheduler..."
	docker compose -f $(COMPOSE_FILE) logs backend | grep -i "scheduler\|monitor\|cleanup\|health"

help:
	@echo "Uso: make [comando]"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  up             : Levanta los servicios y construye las imágenes si es necesario (en modo detached)."
	@echo "  down           : Detiene y elimina los contenedores."
	@echo "  build          : Solo construye las imágenes Docker."
	@echo "  rebuild        : Detiene, construye y levanta los servicios."
	@echo "  logs           : Muestra los logs de todos los servicios (Ctrl+C para salir)."
	@echo "                   Uso: make logs SERVICE_NAME=<nombre_servicio> (ej: make logs SERVICE_NAME=frontend)"
	@echo "  frontend-bash  : Abre un shell bash en el contenedor del frontend."
	@echo "  backend-bash   : Abre un shell bash en el contenedor del backend."
	@echo "  db-bash        : Abre un shell bash en el contenedor de la base de datos."
	@echo "  clean          : Detiene, elimina contenedores y volúmenes (preserva imágenes)."
	@echo "  clean-all      : Limpieza profunda: elimina contenedores, volúmenes e imágenes."
	@echo "  health         : Verifica el estado de salud de todos los servicios."
	@echo "  test-api       : Prueba los endpoints principales de la API."
	@echo "  scheduler-logs : Muestra los logs del scheduler y tareas programadas."
	@echo "  help           : Muestra esta ayuda."


# Documentation Context Checking
.PHONY: docs-check docs-check-git docs-validate-stack docs-setup-hooks

docs-check:
	@echo "🔍 Checking documentation context for entire project..."
	cd backend && python3 -m app.utils.documentation_checker --dir ../

docs-check-git:
	@echo "🔍 Checking documentation context for git changes..."
	cd backend && python3 -m app.utils.documentation_checker --git-changes

docs-validate-stack:
	@echo "🔧 Validating technology stack documentation..."
	cd backend && python3 -m app.utils.documentation_checker --validate-stack

docs-setup-hooks:
	@echo "⚙️  Setting up documentation hooks..."
	python3 scripts/setup_documentation_hooks.py

docs-report:
	@echo "📄 Generating comprehensive documentation report..."
	cd backend && python3 -m app.utils.documentation_checker --dir ../ --output ../documentation_report.json
	@echo "Report saved to documentation_report.json"
