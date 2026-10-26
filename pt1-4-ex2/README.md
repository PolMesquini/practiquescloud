# Exercici 2 — Disseny i Desplegament de VPC, Subxarxes i EC2

## Objectiu

Comprendre la segmentació de xarxes a AWS (VPC i Subnets) i comparar el desplegament manual (interfície gràfica d'AWS) amb el desplegament automatitzat mitjançant Terraform.

## Part A: Disseny de Xarxa

### TopologiaDemana

| Element | Configuració |
|---|---|
| **VPC** | `10.0.0.0/16` (personalitzada) |
| **Zona d'Disponibilitat** | `us-east-1a` (totes les subxarxes) |
| **Subnet A** | `10.0.32.0/25` · 2 instàncies EC2 |
| **Subnet B** | `10.0.30.0/23` · 2 instàncies EC2 |
| **Subnet C** | `10.0.33.0/28` · 2 instàncies EC2 |
| **Total instàncies** | 6 (t3.micro, Amazon Linux 2023) |

### Distribució de CIDR

- VPC: `10.0.0.0/16` → 65.536 direccions IP
- Subnet A (`10.0.32.0/25`) → 128 direccions (10.0.32.0 - 10.0.32.127)
- Subnet B (`10.0.30.0/23`) → 512 direccions (10.0.30.0 - 10.0.31.255)
- Subnet C (`10.0.33.0/28`) → 16 direccions (10.0.33.0 - 10.0.33.15)

_Totes les subxarxes estan no superposibles i caben dins la VPC._

## Part B: Desplegament per Consola d'AWS (GUI)

Desplegament manual des del panell de control d'AWS:

1. **Crear VPC**: `10.0.0.0/16`, amb nom `vpc-pt1-4-ex2`
2. **Crear Internet Gateway**: `igw-pt1-4-ex2`, adjuntar a la VPC
3. **Crear taula de rutes**: `0.0.0.0/0 → IGW`
4. **Crear 3 subxarxes** a `us-east-1a`:
   - `subnet-a`: `10.0.32.0/25`
   - `subnet-b`: `10.0.30.0/23`
   - `subnet-c`: `10.0.33.0/28`
5. **Associar taula de rutes** a les tres subxarxes
6. **Crear Security Group**: HTTP 80 des d'Internet
7. **Desplegar 6 instàncies EC2** (2 per subnét):
   - Tipus: `t3.micro`
   - SO: Amazon Linux 2023
   - IP pública assignada automàticament
   - Apache HTTP Server instal·lat

### Captures de pantalla (Part B)

> Les següents captures es van prendre després del desplegament manual:

- **VPC**: `pt1-4-ex2` amb les seves propietats
- **Subxarxes**: Les 3 subxarxes creades a `us-east-1a` amb les seves CIDRs
- **Instàncies EC2**: 6 instàncies en execució, etiquetades amb els noms corresponents

*(Les captures de pantalla es podrien afegir aquí al rapport final)*

## Part C: Desplegament amb Terraform (IaC)

### Codifont

El codi de Terraform està a la carpeta `pt1-4-ex2/`:

- `main.tf` — Recursos complets (VPC, subxarxes, IGW, SG, 6 EC2)
- `.gitignore` — Exclusions locals
- `.terraform.lock.hcl` — Bloque de proveïdors

### Estructura de carpetes

```text
practiquescloud/
└── pt1-4-ex2/
    ├── assets/
    │   ├── topologia.drawio
    │   ├── topologia.png
    │   ├── vpc_subnets.png
    │   └── ec2_instances.png
    ├── main.tf
    ├── README.md
    └── .gitignore
```

### Desplegament amb Terraform

Des de la carpeta `pt1-4-ex2`:

```bash
# 1. Inicialitza el projecte
terraform init

# 2. Formatea i valida la configuració
terraform fmt -check
terraform validate

# 3. Revisa el pla
terraform plan -out=tfplan

# 4. Aplica el pla
terraform apply tfplan
```

### Resultat del desplegament

El codi Terraform ha estat validat i està preparat per a ser desplegat. Un cop s'hagin destruït les ressources de l'Exercici 1, des de la carpeta `pt1-4-ex2`:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Es desplgaran les següents ressources:

- VPC: `10.0.0.0/16` amb nom `vpc-pt1-4-ex2`
- 3 subxarxes a `us-east-1a`:
  - Subnet A: `10.0.32.0/25`
  - Subnet B: `10.0.30.0/23`
  - Subnet C: `10.0.33.0/28`
- Internet Gateway: `igw-pt1-4-ex2`
- Security Group: `web-pt1-4-ex2` (HTTP 80 des d'Internet)
- 6 instàncies EC2 `t3.micro` amb Amazon Linux 2023 (2 per subnét)

Després de l'aplica, es podran verificar les 6 instàncies accedint a les seves URLs públiques amb HTTP.

### Verificació

1. Obre les URLs al navegador. Cada pàgina mostra el hostname i el subtnet d'origen.
2. Comprova l'estat de les instàncies:

   ```bash
   terraform state show 'aws_instance.web-subnet-a-1'
   terraform state show 'aws_instance.web-subnet-b-1'
   terraform state show 'aws_instance.web-subnet-c-1'
   ```

3. A la consola d'AWS, a **EC2 → Instances**, han d'aparèixer les 6 instàncies amb les etiquetes corresponents.

### Neteja dels recursos

Per evitar costos, elimina tots els recursos quan acabis la pràctica:

```bash
terraform destroy
```

## Decisions de disseny

- **3 subxarxes una sola AZ**: Per Prat adequat a l'exercici, totes les subxarxes compartin `us-east-1a`. Això facilita la gestió, però en un entorn de producció s'utilitzarien múltiples AZs per alta disponibilitat.
- **CIDR planning**: Els CIDRs estan pensats per no superposar-se i ser fàcils d'identificar (`10.0.32.0/25`, `10.0.30.0/23`, `10.0.33.0/28`).
- **6 instàncies t3.micro**: Entra en el nivell gratuït d'AWS (per algunes configuracions), però 6 instàncies poden suposar un cost lleuger. Recorda destruir-les després.
- **IMDSv2 obligatori**: El servei de metadades només accepta tokens IMDSv2 per pràctica de seguretat.
- **HTTP solament**: El Security Group obre només el port 80. No s'obertura SSH directe per aquest exercici.
- **AMI dinàmica**: No es fixa un AMI ID, sinó que es consulta la versió més recent d'Amazon Linux 2023.

## Costos

- Les instàncies `t3.micro` poden entrar al nivell gratuït, però 6 instàncies simultànies poden superar el límit.
- VPC, subxarxes, Internet Gateway i Security Group no tenen cost directe.
- **Destrueix amb `terraform destroy`** quan acabis la pràctica.

## Autor

Pol Mesquini — pràctica de cloud, curs 2026-2027.