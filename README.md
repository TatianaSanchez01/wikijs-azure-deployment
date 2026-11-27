# Wiki.js en AWS con Terraform, RDS, observabilidad y CI/CD

Proyecto académico basado en la rama original `implementacion-aws`.

## Qué despliega

- **Red:** VPC, subred pública con Internet Gateway para EC2, dos subredes privadas en dos AZ para RDS, grupos de seguridad independientes.
- **Aplicación contenerizada:** una instancia EC2 Amazon Linux 2023 que ejecuta Wiki.js 2 con Docker (puerto HTTP 3000).
- **Base de datos gestionada:** Amazon RDS PostgreSQL 15, cifrado EBS, 20 GiB gp3, sin IP pública y acceso únicamente desde el SG de EC2.
- **Secretos:** RDS gestiona la contraseña principal en Secrets Manager. EC2 la consulta con un rol IAM (sin credenciales estáticas en Git ni en el `user_data` de Terraform).
- **Observabilidad:** CloudWatch Agent para memoria y disco de EC2 y logs de arranque/Docker; métricas nativas de EC2/RDS y exportación de logs PostgreSQL, dashboard, 4 alarmas y notificaciones SNS opcionales.
- **CI/CD opción B:** GitHub Actions ejecuta `terraform fmt`, `init`, `validate`, `plan`; `apply` solo con ejecución manual y entorno `iac-aws`.

## Precaución antes de ejecutar `apply`

**No ejecutes `terraform apply` contra una infraestructura existente antes de sacar un respaldo**. La plantilla de EC2 cambia y `user_data_replace_on_change = true` obliga a reemplazar la instancia; además, el disco raíz original se elimina en la terminación. Si hay páginas de Wiki.js guardadas en el PostgreSQL del contenedor antiguo, **se perderán sin una exportación y restauración**. La migración del contenido a RDS es una tarea separada y no está automatizada. Usa `terraform plan` y revisa los cambios.

RDS y CloudWatch tienen costos reales, incluso en una práctica académica. Confirma presupuesto y ejecuta `terraform destroy` cuando termines (con precaución: elimina RDS). La base RDS se crea sin snapshot final **solo para laboratorio**. La URL de Wiki.js usa HTTP, no HTTPS; NO apta para producción pública.

## 1. Preparar AWS

1. Crea un par de claves EC2 (`key_name`) en la región elegida; limita SSH a tu IP actual/32.
2. Crea un **bucket S3 único**, con acceso público bloqueado, cifrado y versionado, para el archivo de estado remoto Terraform. Debe existir **antes** de `terraform init`.
3. Para GitHub Actions configura un **proveedor de identidad OIDC GitHub** (`token.actions.githubusercontent.com`) y un **rol IAM** cuya confianza permita solo `repo:TatianaSanchez01/wikijs-azure-deployment:ref:refs/heads/implementacion-aws` (audiencia `sts.amazonaws.com`). El rol debe tener permisos para crear/gestionar los recursos del proyecto (VPC/EC2/IAM/RDS/CloudWatch/Logs/SNS) y leer/escribir el objeto del estado y `.tflock` en S3; aplica privilegios mínimos según tu cuenta. No concedas `AdministratorAccess` sin justificación.
4. Restringe la confianza del rol IAM al branch `implementacion-aws`; el `apply` está limitado a un disparo manual. Si necesitas revisión obligatoria antes de aplicar, separa `plan` y `apply` en dos jobs y configura un GitHub Environment con aprobación.
5. En GitHub → Settings → Secrets and variables → Actions → **Variables** agrega:

   | Variable | Ejemplo |
   |---|---|
   | `AWS_REGION` | `us-east-1` |
   | `AWS_TERRAFORM_ROLE_ARN` | `arn:aws:iam::123456789012:role/wiki-terraform-actions` |
   | `TF_STATE_BUCKET` | `mi-bucket-terraform-globalmente-unico` |
   | `SSH_ALLOWED_CIDR` | `203.0.113.10/32` |
   | `EC2_KEY_PAIR` | `mi-par-ec2` |

**Importante:** GitHub no ejecuta `apply` automáticamente al hacer push. Debes ir a Actions → Terraform IaC CI/CD (AWS) → Run workflow → seleccionar rama `implementacion-aws` y `apply`.

Documentación: [GitHub OIDC para AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws), [backend S3 con lockfile](https://developer.hashicorp.com/terraform/language/backend/s3).

## 2. Despliegue local (PowerShell)

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
# Modifica my_ip, key_name, alert_email (opcional), etc.
terraform fmt -recursive
terraform init -backend-config="bucket=MI_BUCKET" -backend-config="key=wikijs/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="encrypt=true" -backend-config="use_lockfile=true"
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output wikijs_url
```

Si ya existe un `terraform.tfstate` local, primero haz un respaldo y utiliza `terraform init -migrate-state` para migrar al bucket S3. No elimines el estado original hasta verificar que quedó almacenado correctamente.

## 3. Validación de observabilidad

- CloudWatch → Dashboards → `<project_name>-observability`: CPU/memoria/disco EC2 y CPU/conexiones/almacenamiento RDS.
- CloudWatch → Log groups → `/aws/ec2/<project_name>/wikijs`: logs de `cloud-init` y del contenedor Docker. RDS genera otro log group `/aws/rds/instance/<project_name>-postgres/postgresql`.
- CloudWatch → Alarms: CPU EC2 >80%, memoria >85%, status check EC2 fallido y RDS con menos de 2 GiB libres.
- Si `alert_email` no está vacío, confirma el correo enviado por SNS antes de probar notificaciones.
- En la instancia: `sudo systemctl status amazon-cloudwatch-agent`, `sudo docker ps`, `sudo docker logs wikijs --tail 50`.
- Observación: el dashboard y alarmas existen inmediatamente tras aplicar, pero los gráficos y logs dependen del arranque correcto del agente y del tiempo de ingesta de métricas.

## 4. Migrar una instalación ya existente

Antes de cambiar EC2, crear un dump de PostgreSQL antiguo desde la instancia original, guardarlo **fuera de la instancia** y verificar que se puede restaurar. Por ejemplo:

```bash
# En la instancia antigua (si postgres se llama wikijs-postgres):
sudo docker exec wikijs-postgres pg_dump -U wikijs -d wikijs -Fc > wikijs.backup
```

Copia el archivo a un equipo seguro/S3. Tras crear RDS y antes de usar la nueva Wiki.js, restaura el dump mediante `pg_restore` usando un cliente PostgreSQL con conectividad privada a RDS y TLS. No apuntes simultáneamente dos aplicaciones que escriban datos incompatibles a la misma base. Coordina una ventana de migración y verifica páginas/usuarios tras la restauración.

Para garantizar la migración sin pérdida de servicio, el despliegue debería refactorizarse para **crear primero RDS, restaurar datos y reemplazar EC2 después**; el código actual no automatiza esa transición.

## 5. Evidencia para la entrega

1. Captura de ejecución GitHub Actions con `fmt`, `validate` y `plan` completados.
2. Captura de `Run workflow` (acción `apply`) y posterior `terraform output`.
3. Vista de los servicios en AWS: EC2, RDS (subred privada) y red.
4. Dashboard de CloudWatch con métricas reales.
5. Log group mostrando logs del contenedor y lista de alarmas; si SNS está habilitado, muestra la suscripción confirmada.

## 6. Limpieza

```powershell
terraform destroy
```

`destroy` elimina la base RDS y el contenido si no existe snapshot independiente; no lo ejecutes si necesitas preservar datos. El bucket del backend S3 es externo al proyecto y se limpia por separado solo tras verificar que no necesitas el estado.
