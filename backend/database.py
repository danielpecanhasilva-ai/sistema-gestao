import sqlite3

from flask import g

import config


def get_db():
    """Abre (uma vez por requisição) a conexão com o banco."""
    if "db" not in g:
        g.db = sqlite3.connect(config.DATABASE)
        g.db.row_factory = sqlite3.Row          # permite acessar colunas pelo nome
        g.db.execute("PRAGMA foreign_keys = ON")  # no SQLite vem desligado por padrão
    return g.db


def close_db(erro=None):
    """Fecha a conexão ao fim da requisição."""
    db = g.pop("db", None)
    if db is not None:
        db.close()
