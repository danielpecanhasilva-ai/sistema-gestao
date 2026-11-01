import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Caminho do banco SQLite (pode ser trocado pela variável de ambiente GESTAO_DB)
DATABASE = os.environ.get(
    "GESTAO_DB",
    os.path.join(BASE_DIR, "..", "database", "gestao.db"),
)

# Pasta das telas (HTML, CSS, JS) que o Flask também serve
FRONTEND_DIR = os.path.join(BASE_DIR, "..", "frontend")
