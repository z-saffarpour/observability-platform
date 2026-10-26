import ipaddress
import os
import re
from contextlib import asynccontextmanager
from secrets import compare_digest
from typing import Literal

import psycopg
from psycopg.rows import dict_row
from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, Field, field_validator

DATABASE_URL = os.environ["DATABASE_URL"]
ADMIN_USER = os.environ["ADMIN_USER"]
ADMIN_PASSWORD = os.environ["ADMIN_PASSWORD"]
if not ADMIN_PASSWORD or len(ADMIN_PASSWORD) < 16:
    raise RuntimeError("ADMIN_PASSWORD must be at least 16 characters")

security = HTTPBasic()
EXPORTERS = {"windows_exporter": 9182, "sql_exporter": 9399, "node_exporter": 9100,
             "postgres_exporter": 9187, "mysql_exporter": 9104}
HOST_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$")


def db():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)


@asynccontextmanager
async def lifespan(app: FastAPI):
    with db() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS monitoring_targets (
                id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                hostname TEXT NOT NULL,
                address TEXT NOT NULL,
                exporter TEXT NOT NULL,
                port INTEGER NOT NULL CHECK(port BETWEEN 1 AND 65535),
                environment TEXT NOT NULL,
                datacenter TEXT NOT NULL,
                enabled BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                UNIQUE(address, exporter, port)
            )
        """)
    yield


app = FastAPI(title="Observability Target Manager", lifespan=lifespan,
              docs_url=None, redoc_url=None, openapi_url=None)


def authenticate(credentials: HTTPBasicCredentials = Depends(security)):
    if not (compare_digest(credentials.username, ADMIN_USER)
            and compare_digest(credentials.password, ADMIN_PASSWORD)):
        raise HTTPException(401, "Invalid credentials",
                            headers={"WWW-Authenticate": "Basic"})
    return credentials.username


class Target(BaseModel):
    hostname: str = Field(min_length=1, max_length=253)
    address: str = Field(min_length=1, max_length=253)
    exporter: Literal["windows_exporter", "sql_exporter", "node_exporter",
                      "postgres_exporter", "mysql_exporter"]
    port: int = Field(ge=1, le=65535)
    environment: str = Field(min_length=1, max_length=64)
    datacenter: str = Field(min_length=1, max_length=64)
    enabled: bool = True

    @field_validator("address")
    @classmethod
    def validate_address(cls, value):
        value = value.strip()
        try:
            ipaddress.ip_address(value)
        except ValueError:
            if not HOST_PATTERN.fullmatch(value) or ".." in value:
                raise ValueError("Expected an IP address or DNS hostname")
        return value


@app.get("/health")
def health():
    with db() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok"}


@app.get("/")
def index(_: str = Depends(authenticate)):
    return FileResponse("static/index.html")


@app.get("/api/targets")
def list_targets(_: str = Depends(authenticate)):
    with db() as conn:
        return conn.execute("SELECT * FROM monitoring_targets ORDER BY id DESC").fetchall()


@app.post("/api/targets", status_code=201)
def add_target(target: Target, _: str = Depends(authenticate)):
    try:
        with db() as conn:
            return conn.execute("""
                INSERT INTO monitoring_targets
                (hostname,address,exporter,port,environment,datacenter,enabled)
                VALUES (%(hostname)s,%(address)s,%(exporter)s,%(port)s,
                        %(environment)s,%(datacenter)s,%(enabled)s)
                RETURNING *
            """, target.model_dump()).fetchone()
    except psycopg.errors.UniqueViolation:
        raise HTTPException(409, "Target already exists")


@app.put("/api/targets/{target_id}")
def update_target(target_id: int, target: Target, _: str = Depends(authenticate)):
    try:
        with db() as conn:
            row = conn.execute("""
                UPDATE monitoring_targets SET
                    hostname=%(hostname)s,address=%(address)s,exporter=%(exporter)s,
                    port=%(port)s,environment=%(environment)s,datacenter=%(datacenter)s,
                    enabled=%(enabled)s,updated_at=now()
                WHERE id=%(id)s RETURNING *
            """, {**target.model_dump(), "id": target_id}).fetchone()
            if row is None:
                raise HTTPException(404, "Target not found")
            return row
    except psycopg.errors.UniqueViolation:
        raise HTTPException(409, "Target already exists")


@app.delete("/api/targets/{target_id}", status_code=204)
def delete_target(target_id: int, _: str = Depends(authenticate)):
    with db() as conn:
        row = conn.execute("DELETE FROM monitoring_targets WHERE id=%s RETURNING id",
                           (target_id,)).fetchone()
    if row is None:
        raise HTTPException(404, "Target not found")


@app.get("/api/discovery/{exporter}")
def discovery(exporter: str):
    # Read-only endpoint: restrict its network exposure to trusted Prometheus hosts.
    if exporter not in EXPORTERS:
        raise HTTPException(404, "Unknown exporter")
    with db() as conn:
        targets = conn.execute("""
            SELECT hostname,address,port,environment,datacenter
            FROM monitoring_targets WHERE exporter=%s AND enabled=true
            ORDER BY id
        """, (exporter,)).fetchall()
    return [{"targets": [f"{row['address']}:{row['port']}"],
             "labels": {"hostname": row["hostname"],
                        "environment": row["environment"],
                        "datacenter": row["datacenter"]}} for row in targets]
