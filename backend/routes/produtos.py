import math

from flask import Blueprint, jsonify, request

from database import get_db

bp = Blueprint("produtos", __name__, url_prefix="/api/produtos")


def produto_para_dict(linha):
    d = dict(linha)
    d["ativo"] = bool(d["ativo"])
    d["estoque_baixo"] = d["estoque"] < d["estoque_minimo"]  # RF05
    return d


def para_inteiro(valor):
    """Converte para int ou levanta ValueError/TypeError."""
    if isinstance(valor, bool):
        raise ValueError
    if isinstance(valor, float) and not valor.is_integer():
        raise ValueError
    return int(valor)


def validar(dados):
    """Valida os dados de um produto (RNF04). Devolve (valores, lista_de_erros)."""
    erros = []

    nome = dados.get("nome")
    if not isinstance(nome, str) or not nome.strip():
        erros.append("O nome é obrigatório.")
        nome = ""
    elif len(nome.strip()) > 100:
        erros.append("O nome deve ter no máximo 100 caracteres.")
    nome = nome.strip()

    categoria = dados.get("categoria")
    if categoria in (None, ""):
        categoria = None
    elif not isinstance(categoria, str) or len(categoria.strip()) > 50:
        erros.append("A categoria deve ter no máximo 50 caracteres.")
        categoria = None
    else:
        categoria = categoria.strip()

    preco = None
    try:
        preco = round(float(dados.get("preco")), 2)
        if not math.isfinite(preco) or preco <= 0:
            erros.append("O preço deve ser maior que zero.")
    except (TypeError, ValueError):
        erros.append("O preço deve ser um número.")

    estoque = None
    try:
        estoque = para_inteiro(dados.get("estoque"))
        if estoque < 0:
            erros.append("O estoque não pode ser negativo.")
    except (TypeError, ValueError):
        erros.append("O estoque deve ser um número inteiro.")

    estoque_minimo = 5  # padrão do banco
    if dados.get("estoque_minimo") not in (None, ""):
        try:
            estoque_minimo = para_inteiro(dados.get("estoque_minimo"))
            if estoque_minimo < 0:
                erros.append("O estoque mínimo não pode ser negativo.")
        except (TypeError, ValueError):
            erros.append("O estoque mínimo deve ser um número inteiro.")

    valores = {
        "nome": nome,
        "categoria": categoria,
        "preco": preco,
        "estoque": estoque,
        "estoque_minimo": estoque_minimo,
    }
    return valores, erros


def ler_json():
    dados = request.get_json(silent=True)
    return dados if isinstance(dados, dict) else None


def buscar_por_id(id_):
    linha = get_db().execute("SELECT * FROM produtos WHERE id = ?", (id_,)).fetchone()
    return linha


# ---------------------------------------------------------------- GET /api/produtos
@bp.get("")
def listar():
    busca = request.args.get("busca", "").strip()
    todos = request.args.get("todos") == "1"   # ?todos=1 inclui os inativos

    sql = "SELECT * FROM produtos WHERE 1 = 1"
    params = []
    if not todos:
        sql += " AND ativo = 1"
    if busca:
        sql += " AND (nome LIKE ? OR categoria LIKE ?)"
        params += [f"%{busca}%", f"%{busca}%"]
    sql += " ORDER BY nome COLLATE NOCASE"

    linhas = get_db().execute(sql, params).fetchall()
    return jsonify([produto_para_dict(l) for l in linhas]), 200


# ---------------------------------------------------------------- POST /api/produtos
@bp.post("")
def criar():
    dados = ler_json()
    if dados is None:
        return jsonify(erros=["Envie os dados em formato JSON."]), 400

    valores, erros = validar(dados)
    if erros:
        return jsonify(erros=erros), 400

    db = get_db()
    cursor = db.execute(
        "INSERT INTO produtos (nome, categoria, preco, estoque, estoque_minimo) "
        "VALUES (:nome, :categoria, :preco, :estoque, :estoque_minimo)",
        valores,
    )
    db.commit()
    return jsonify(produto_para_dict(buscar_por_id(cursor.lastrowid))), 201


# ---------------------------------------------------------------- GET /api/produtos/<id>
@bp.get("/<int:id_>")
def detalhar(id_):
    linha = buscar_por_id(id_)
    if linha is None:
        return jsonify(erro="Produto não encontrado."), 404
    return jsonify(produto_para_dict(linha)), 200


# ---------------------------------------------------------------- PUT /api/produtos/<id>
@bp.put("/<int:id_>")
def editar(id_):
    atual = buscar_por_id(id_)
    if atual is None:
        return jsonify(erro="Produto não encontrado."), 404

    dados = ler_json()
    if dados is None:
        return jsonify(erros=["Envie os dados em formato JSON."]), 400

    valores, erros = validar(dados)
    if erros:
        return jsonify(erros=erros), 400

    # "ativo" é opcional: permite reativar um produto inativado
    valores["ativo"] = int(bool(dados["ativo"])) if "ativo" in dados else atual["ativo"]
    valores["id"] = id_

    db = get_db()
    db.execute(
        "UPDATE produtos SET nome = :nome, categoria = :categoria, preco = :preco, "
        "estoque = :estoque, estoque_minimo = :estoque_minimo, ativo = :ativo "
        "WHERE id = :id",
        valores,
    )
    db.commit()
    return jsonify(produto_para_dict(buscar_por_id(id_))), 200


# ---------------------------------------------------------------- DELETE /api/produtos/<id>
@bp.delete("/<int:id_>")
def inativar(id_):
    """Não apaga de verdade: só marca como inativo (RN04)."""
    if buscar_por_id(id_) is None:
        return jsonify(erro="Produto não encontrado."), 404

    db = get_db()
    db.execute("UPDATE produtos SET ativo = 0 WHERE id = ?", (id_,))
    db.commit()
    return jsonify(mensagem="Produto inativado."), 200
