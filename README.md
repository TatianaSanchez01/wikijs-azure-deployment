# Wiki.js AWS Learner Lab — Terraform CI/CD y observabilidad

Opción B: GitHub Actions despliega infraestructura Terraform sin crear roles, políticas ni perfiles IAM. Usa credenciales temporales del laboratorio.

## Arquitectura
EC2 Amazon Linux 2023 (t3.medium por defecto) con Docker Compose: Wiki.js, Prometheus, Grafana, Node Exporter, cAdvisor, PostgreSQL Exporter y Blackbox Exporter. RDS PostgreSQL 15 privado en dos subredes de distintas AZ (instancia Single-AZ). CloudWatch: métricas nativas, dashboard, alarmas CPU/estado EC2 y almacenamiento RDS, exportación de logs PostgreSQL si el laboratorio lo permite. Grafana por túnel SSH; exporters y Prometheus no tienen puertos públicos. cAdvisor requiere privilegios de host; entorno académico únicamente.

## Preparación
1. Inicia el laboratorio y crea un key pair EC2 en la región. Obtén tu IP pública /32.
2. Crea un bucket S3 único privado, cifrado y versionado para estado Terraform. No compartas el estado: contiene contraseñas y user_data. Permite lectura/escritura del estado y archivo .tflock a las credenciales del laboratorio.
3. GitHub Settings > Secrets and variables > Actions: configura secrets AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, TF_VAR_DB_PASSWORD y TF_VAR_GRAFANA_PASSWORD (contraseñas distintas, 8–64 caracteres A-Z a-z 0-9 _ -). Renueva las tres credenciales AWS cuando expiren. Variables: AWS_REGION (us-east-1), TF_STATE_BUCKET, SSH_ALLOWED_CIDR, EC2_KEY_PAIR.
4. CI en push/PR a wiki-aws-improvements: formato, init sin backend y validate. Plan/apply solo manual desde dicha rama y con credenciales vigentes. Si GitHub no muestra Run workflow porque el archivo no está en la rama por defecto, integra primero el workflow mediante PR o usa ejecución local. No se sube plan/state como artefacto público.
5. Ejecuta plan antes de apply; no se aplica automáticamente.

## PowerShell local
Configura las credenciales AWS temporales en tu sesión, copia terraform.tfvars.example a terraform.tfvars y ajusta IP, key pair, región. Define TF_VAR_db_password y TF_VAR_grafana_password de forma privada en tu entorno.

    terraform fmt -recursive
    terraform init -backend-config="bucket=MI_BUCKET" -backend-config="key=wikijs/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="encrypt=true" -backend-config="use_lockfile=true"
    terraform validate
    terraform plan -out=tfplan
    terraform apply tfplan
    terraform output

Si existe estado local, respáldalo y migra con init -migrate-state antes de usar S3. No despliegues dos veces con estados distintos.

## Observabilidad y pruebas
Abre Wiki.js con terraform output wikijs_url. HTTP sin TLS público: solo demo con acceso limitado a tu IP. En PowerShell:

    ssh -i RUTA.pem -L 3001:127.0.0.1:3001 ec2-user@IP_EC2

Abre http://localhost:3001, usuario admin, contraseña configurada. Dashboard Wiki.js - Observabilidad: HTTP, latencia, CPU/memoria, contenedores y PostgreSQL. Espera varios minutos tras el arranque. En EC2:

    sudo cloud-init status --long
    cd /opt/wikijs
    sudo docker compose ps
    sudo docker compose logs --tail 50 wikijs

CloudWatch: dashboard wikijs-aws-observability, alarmas nativas y logs RDS en /aws/rds/instance/wikijs-aws-postgres/postgresql. Los logs de Wiki.js se consultan por SSH (sin agente ni IAM); no se centralizan en CloudWatch. No hay trazas distribuidas. Captura evidencias del pipeline, Wiki.js, RDS, Grafana y CloudWatch con datos reales.

## Seguridad y limpieza
Contraseñas en variables sensibles no se muestran normalmente en CLI, pero quedan en estado, user_data de EC2 y configuración Docker; no es una solución de producción. Restringe acceso a GitHub, S3 y EC2. La contraseña de RDS se usa también por el exporter para simplificar el laboratorio; en producción usar un usuario de monitoreo limitado.
Cambiar user_data reemplaza EC2 y elimina su disco. Antes de aplicar sobre la instalación antigua, exporta PostgreSQL y guarda el dump fuera de EC2; restaura en RDS antes de habilitar Wiki.js. No se automatiza migración. RDS sin snapshot final es una decisión de laboratorio. Revisa permisos y costos de RDS, EC2, S3 y CloudWatch. Si el laboratorio deniega CloudWatch o la exportación RDS, revisa restricciones antes de aplicar. Al finalizar, terraform destroy con el mismo backend y credenciales vigentes (borra datos); conserva respaldo si corresponde.
