"""
Three-tier EKS demo — backend API
Author: Yashas Suresh (https://github.com/yashassuresh775)
"""

from __future__ import annotations

import os
from contextlib import contextmanager

import psycopg2
from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
from psycopg2.extras import RealDictCursor

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://app:app@postgres:5432/appdb",
)

app = Flask(__name__)
metrics = PrometheusMetrics(app, path="/metrics")
metrics.info("backend_app", "Three-tier EKS backend", version="1.0.0")


@contextmanager
def get_conn():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS items (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )


@app.before_request
def ensure_schema():
    if not getattr(app, "_db_ready", False):
        try:
            init_db()
            app._db_ready = True
        except psycopg2.OperationalError:
            pass


@app.get("/api/health")
def health():
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return jsonify({"status": "ok", "tier": "backend", "database": "up"})
    except psycopg2.Error as exc:
        return jsonify({"status": "degraded", "database": "down", "detail": str(exc)}), 503


@app.get("/api/items")
def list_items():
    with get_conn() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name, created_at FROM items ORDER BY id ASC")
            rows = cur.fetchall()
    return jsonify(
        [
            {
                "id": r["id"],
                "name": r["name"],
                "created_at": r["created_at"].isoformat() if r["created_at"] else None,
            }
            for r in rows
        ]
    )


@app.post("/api/items")
def create_item():
    payload = request.get_json(silent=True) or {}
    name = payload.get("name")
    if not name or not isinstance(name, str) or not name.strip():
        return jsonify({"error": "JSON body must include non-empty string field 'name'"}), 400
    name = name.strip()
    with get_conn() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "INSERT INTO items (name) VALUES (%s) RETURNING id, name, created_at",
                (name,),
            )
            row = cur.fetchone()
    return (
        jsonify(
            {
                "id": row["id"],
                "name": row["name"],
                "created_at": row["created_at"].isoformat() if row["created_at"] else None,
            }
        ),
        201,
    )


try:
    init_db()
    app._db_ready = True
except Exception:
    app._db_ready = False


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8000, debug=True)
