# Blue/Green Deployment with Nginx (Stage 2 DevOps Task)

## Overview
This project implements a Blue/Green Node.js service deployment behind Nginx, featuring automatic failover and header propagation.  

Nginx routes traffic to Blue by default and automatically switches to Green in case of Blue failure (HTTP 5xx or timeout).

---

## 🧰 Stack
- Docker Compose
- Nginx
- Two Node.js containers (`Blue` and `Green`)

---

## 🔧 Setup

### 1️⃣ Clone this repository
```bash
git clone https://github.com/<your-username>/stage2-devops.git
cd stage2-devops
