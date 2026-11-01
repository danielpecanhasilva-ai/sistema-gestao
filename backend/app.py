import os

from flask import Flask, jsonify, request
from flask_cors import CORS

import config
from database import close_db
from routes.produtos import bp as produtos_bp

app = Flask(__name__, static_folder=config.FRONTEND_DIR, static_url_path="")
CORS(app)  # libera o front-end em desenvolvimento (RNF: erros de CORS)

app.teardown_appcontext(close_db)
app.register_blueprint(produtos_bp)


@app.get("/")
def inicio():
    return app.send_static_file("produtos.html")


def erro_json(codigo, mensagem):
    """Nas rotas /api devolve JSON; nas demais, a página de erro padrão."""
    def tratador(e):
        if request.path.startswith("/api"):
            return jsonify(erro=mensagem), codigo
        return e
    return tratador


app.register_error_handler(404, erro_json(404, "Recurso não encontrado."))
app.register_error_handler(405, erro_json(405, "Método não permitido."))
app.register_error_handler(500, erro_json(500, "Erro interno do servidor."))


if __name__ == "__main__":
    if not os.path.exists(config.DATABASE):
        raise SystemExit(
            "Banco não encontrado em: " + os.path.abspath(config.DATABASE) + "\n"
            "Crie-o com: sqlite3 database/gestao.db < database/schema.sql"
        )
    app.run(debug=True)
