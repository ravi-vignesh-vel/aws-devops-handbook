# Cloud & AWS Fundamentals — Short Notes

*Read top to bottom: each topic builds on the one before it.*

---

## 1. What Is Cloud Computing?

**Simple idea:** Instead of buying and maintaining your own servers, you **rent computing power (servers, storage, databases, networking) over the internet** and pay only for what you use — like electricity from the grid instead of running your own generator.

| Traditional (On-Premises) | Cloud |
|---|---|
| Buy hardware upfront (big capital cost) | Pay-as-you-go (operating cost) |
| Weeks/months to set up a server | Minutes to launch a server |
| Capacity guessed in advance | Scale up or down on demand |
| You maintain data center, power, cooling | Provider maintains it |

**Key characteristics:** on-demand self-service, pay-per-use, elastic scaling, global reach, high availability.

**Example:** A shopping site expects 10x traffic on a sale day. On-prem: buy 10x servers that sit idle later. Cloud: scale up for the sale, scale back down after.

---

## 2. Service Models: IaaS, PaaS, SaaS

The models differ in **how much you manage vs. how much the provider manages.**

**Pizza analogy:**

- **IaaS** = buy ingredients, cook at home (you do most work)
- **PaaS** = order a pizza kit, you just bake and add toppings
- **SaaS** = dine at the restaurant (just eat)

| Model | You Manage | Provider Manages | AWS Example | Other Example |
|---|---|---|---|---|
| **IaaS** — Infrastructure as a Service | OS, runtime, apps, data | Servers, storage, networking | EC2, EBS, VPC | Azure VMs |
| **PaaS** — Platform as a Service | Your app and data | OS, runtime, scaling, patching | Elastic Beanstalk, RDS | Heroku |
| **SaaS** — Software as a Service | Just use it (and your data/settings) | Everything | WorkMail, Amazon Chime | Gmail, Salesforce |

**Remember:** IaaS = most control, most work. SaaS = least control, least work.

---

## 3. Public, Private and Hybrid Cloud

| Type | What It Is | Best For | Trade-off |
|---|---|---|---|
| **Public Cloud** | Resources owned by a provider (AWS, Azure, GCP) and shared across many customers, delivered over the internet | Startups, web apps, variable workloads | Less control over underlying hardware |
| **Private Cloud** | Cloud infrastructure used by **one organization only** (own data center or dedicated hosting) | Strict compliance, sensitive data | High cost, you maintain it |
| **Hybrid Cloud** | **Mix of public + private (or on-prem)**, connected together | Gradual migration, keep sensitive data on-prem while using cloud for the rest | More complex to manage |

**Analogy:** Public = taking a taxi. Private = owning a car. Hybrid = own a car for daily use, take taxis when you need extra capacity.

**AWS hybrid tools:** Direct Connect (private network link), Site-to-Site VPN, AWS Outposts (AWS hardware in your data center).

---

## 4. Introduction to AWS

**Amazon Web Services (AWS)** is the world's most widely used cloud platform, offering 200+ services. Launched in 2006.

**Why companies choose AWS:** huge service range, global infrastructure, pay-as-you-go pricing, strong security tooling, mature ecosystem.

**Core service categories (starter map):**

| Category | Purpose | Key Services |
|---|---|---|
| Compute | Run applications | EC2, Lambda, ECS/EKS |
| Storage | Store data | S3, EBS, EFS |
| Database | Managed databases | RDS, DynamoDB |
| Networking | Connect and isolate resources | VPC, Route 53, ELB |
| Security & Identity | Control access | IAM, KMS |
| Monitoring | Observe and audit | CloudWatch, CloudTrail |

**How you use AWS:** AWS Management Console (web UI), AWS CLI (terminal), SDKs (code), Infrastructure as Code (CloudFormation, Terraform).

**Cost tip:** The AWS Free Tier lets you practice at low/no cost — always set a billing alarm and stop or delete unused resources.

---

## 5. Regions, Availability Zones and Edge Locations

**Think of it like a courier network:**

- **Region** = a city's main hub
- **Availability Zone (AZ)** = separate warehouses inside that city
- **Edge Location** = local pickup points near customers

```
AWS Global Infrastructure
│
├── Region (e.g., ap-south-1 Mumbai)
│     ├── AZ-a  (one or more data centers)
│     ├── AZ-b  (separate power, cooling, network)
│     └── AZ-c
│
└── Edge Locations (hundreds worldwide)
      → cache content close to users (CloudFront, Route 53)
```

| Term | Meaning | Why It Matters |
|---|---|---|
| **Region** | A geographic area (e.g., Mumbai `ap-south-1`, N. Virginia `us-east-1`) containing multiple AZs. Regions are **isolated** from each other. | Choose based on: **latency** (close to users), **compliance/data residency**, **service availability**, and **cost** |
| **Availability Zone (AZ)** | One or more physical data centers in a Region with independent power, cooling and networking, connected by low-latency links | Spread across 2+ AZs for **high availability** — if one AZ fails, the app keeps running |
| **Edge Location** | A site used by **CloudFront (CDN)** and Route 53 to serve content from a location close to the user | Faster load times, lower latency for global users |

**Common mistakes:**

- Putting everything in **one AZ** → single point of failure.
- Assuming data automatically copies across **Regions** → it doesn't; you must set that up (e.g., S3 cross-region replication).

**Example:** A video site hosted in Mumbai uses 2 AZs for resilience, and CloudFront edge locations so a viewer in London gets cached content from a nearby edge instead of Mumbai.

---

## 6. Shared Responsibility Model

**Core idea:** Security is a **partnership** — AWS secures the cloud itself; **you** secure what you put in it.

**Apartment analogy:** The landlord secures the building (gate, structure, elevator). You lock your own door and protect your belongings.

| AWS Responsibility — "Security **OF** the Cloud" | Customer Responsibility — "Security **IN** the Cloud" |
|---|---|
| Physical data centers and hardware | Your data and its encryption |
| Global network and infrastructure | IAM users, roles, permissions, MFA |
| Hypervisor and managed service software | Guest OS patching (on EC2) |
| Facilities, power, cooling | Security Groups, firewall and network config |
| | Application code and configuration |

**It shifts by service type:**

| Service | AWS Manages | You Manage |
|---|---|---|
| **EC2** (IaaS) | Hardware, hypervisor | OS patches, firewall, apps, data |
| **RDS** (managed DB) | Hardware, OS, DB patching | Data, access control, DB settings, backups config |
| **S3 / Lambda** (higher-level) | Almost the entire stack | Your data, bucket policies/permissions, function code |

**Real-world example:** A publicly exposed S3 bucket leaking data is **not an AWS failure — it's the customer's misconfiguration.**

**Golden rules:** enable MFA, follow least-privilege IAM, encrypt data, never hardcode credentials, and review access regularly.

---

## 7. AWS Well-Architected Framework

**What it is:** A set of AWS best practices and questions to help you check whether your cloud workload is **secure, reliable, fast, cost-efficient and easy to run**. Think of it as a **building inspection checklist** — it doesn't build the house for you, but it tells you where the weak spots are before they become problems.

**It is organized into 6 pillars:**

| Pillar | Core Question | Key Practices | Example AWS Services |
|---|---|---|---|
| **Operational Excellence** | Can we run, monitor and improve it smoothly? | Automate with code (IaC), small frequent changes, learn from failures, runbooks | CloudFormation, CloudWatch, Systems Manager |
| **Security** | Is our data and system protected? | Least-privilege IAM, MFA, encrypt data, enable logging, traceability | IAM, KMS, CloudTrail, GuardDuty |
| **Reliability** | Does it recover from failure and keep working? | Multi-AZ design, backups, auto-recovery, test failover, avoid single points of failure | Auto Scaling, ELB, Route 53, RDS Multi-AZ |
| **Performance Efficiency** | Are we using the right resources efficiently? | Pick the right instance/storage type, use caching and CDN, review as needs change | EC2 instance types, CloudFront, ElastiCache |
| **Cost Optimization** | Are we avoiding unnecessary spend? | Right-size, pay only for what you use, use Savings Plans/Reserved/Spot, tag and track costs | Cost Explorer, Budgets, Trusted Advisor |
| **Sustainability** | Are we minimizing environmental impact? | Maximize utilization, use efficient and managed services, avoid idle resources | Graviton instances, serverless services |

**Easy way to remember:** *O-S-R-P-C-S* — **O**perations, **S**ecurity, **R**eliability, **P**erformance, **C**ost, **S**ustainability.

**Design principles behind it:** stop guessing capacity, test at production scale, automate, allow evolutionary architectures, make decisions using data, and rehearse failures ("game days").

**How it connects to what you learned above:**

- Using **2+ Availability Zones** → *Reliability*
- Following the **Shared Responsibility Model** (IAM, encryption, patching) → *Security*
- Using **CloudFront / edge locations** → *Performance Efficiency*
- Choosing **the right service model** (managed PaaS vs. self-managed IaaS) → *Operational Excellence* and *Cost Optimization*

**Example:** An e-commerce app review finds it runs in a single AZ (Reliability risk), uses an over-sized server (Cost risk) and has no logging (Security/Operations risk). The Framework makes you fix each one in a structured way.

**AWS Well-Architected Tool:** A free tool in the AWS Console. You answer questions about your workload and it shows **risks and improvement recommendations** per pillar.

**Interview one-liner:** *"The Well-Architected Framework has six pillars — Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization and Sustainability — and is used to review workloads against AWS best practices."*

---

## Quick Recap

| Topic | One-Line Summary |
|---|---|
| Cloud Computing | Rent IT resources over the internet, pay for what you use |
| IaaS / PaaS / SaaS | More control + more work → less control + less work |
| Public / Private / Hybrid | Shared provider cloud / dedicated cloud / a mix of both |
| AWS | The leading cloud platform with 200+ services |
| Region | Geographic location containing multiple AZs |
| Availability Zone | Isolated data center group inside a Region — use 2+ for HA |
| Edge Location | Nearby cache point for fast content delivery |
| Shared Responsibility | AWS secures the cloud; you secure what's in it |
| Well-Architected Framework | 6 pillars (Ops, Security, Reliability, Performance, Cost, Sustainability) to review any workload |
