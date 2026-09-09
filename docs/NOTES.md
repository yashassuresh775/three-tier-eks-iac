# three-tier-eks-iac notes

This repository is an **original** three-tier EKS lab authored for
https://github.com/yashassuresh775/three-tier-eks-iac.

Differences from common Node + Mongo workshop repos:

- Backend is **Flask + Gunicorn**, not Node/Express
- Database is **PostgreSQL 16**, not MongoDB
- Images push to **private ECR**, not a shared public ECR gallery
- Terraform includes **IRSA** for Cluster Autoscaler and AWS LB Controller
- **Prometheus + Grafana** are integrated via **kube-prometheus-stack** (Helm);
  the Flask API exposes `/metrics`, scraped by a **ServiceMonitor**
- Grafana login: `admin` / `prom-operator` (dashboard **1860** pre-loaded)

Follow the numbered sections in the root [README.md](../README.md) for the full lab flow.
