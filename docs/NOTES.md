# Project 2 notes

This repository is an **original** three-tier EKS lab authored for
https://github.com/yashassuresh775/project-2.

Differences from common Node + Mongo workshop repos:

- Backend is **Flask + Gunicorn**, not Node/Express
- Database is **PostgreSQL 16**, not MongoDB
- Images push to **private ECR**, not a shared public ECR gallery
- Terraform includes **IRSA** for Cluster Autoscaler and AWS LB Controller
- Monitoring is optional via **kube-prometheus-stack** (Grafana admin / prom-operator)

Follow the numbered sections in the root [README.md](../README.md) for the full lab flow.
