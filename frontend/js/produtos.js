const formatoReal = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });

const el = {
  form: document.getElementById("form-produto"),
  titulo: document.getElementById("titulo-form"),
  id: document.getElementById("produto-id"),
  nome: document.getElementById("nome"),
  categoria: document.getElementById("categoria"),
  preco: document.getElementById("preco"),
  estoque: document.getElementById("estoque"),
  minimo: document.getElementById("estoque_minimo"),
  salvar: document.getElementById("btn-salvar"),
  cancelar: document.getElementById("btn-cancelar"),
  mensagem: document.getElementById("mensagem"),
  busca: document.getElementById("busca"),
  todos: document.getElementById("todos"),
  lista: document.getElementById("lista"),
  vazio: document.getElementById("vazio"),
};

let produtos = [];  // última lista carregada

function mostrarMensagem(texto, tipo) {
  el.mensagem.textContent = texto || "";
  el.mensagem.className = tipo || "";
}

// ------------------------------------------------------------- listar
async function carregar() {
  const params = new URLSearchParams();
  if (el.busca.value.trim()) params.set("busca", el.busca.value.trim());
  if (el.todos.checked) params.set("todos", "1");
  try {
    produtos = await api("/produtos?" + params.toString());
    desenhar();
  } catch (e) {
    mostrarMensagem(e.message, "erro");
  }
}

function celula(texto, classe) {
  const td = document.createElement("td");
  td.textContent = texto;               // textContent evita injeção de HTML
  if (classe) td.className = classe;
  return td;
}

function botao(texto, classe, aoClicar) {
  const b = document.createElement("button");
  b.type = "button";
  b.textContent = texto;
  b.className = "btn btn-pequeno " + (classe || "");
  b.addEventListener("click", aoClicar);
  return b;
}

function atualizarResumo() {
  const ativos = produtos.filter((p) => p.ativo);
  document.getElementById("r-total").textContent = ativos.length;
  document.getElementById("r-baixo").textContent = ativos.filter((p) => p.estoque_baixo).length;
  document.getElementById("r-valor").textContent =
    formatoReal.format(ativos.reduce((soma, p) => soma + p.preco * p.estoque, 0));
}

function desenhar() {
  el.lista.replaceChildren();
  el.vazio.hidden = produtos.length > 0;
  atualizarResumo();

  for (const p of produtos) {
    const tr = document.createElement("tr");
    if (p.estoque_baixo && p.ativo) tr.classList.add("baixo");
    if (!p.ativo) tr.classList.add("inativo");

    const tdNome = celula(p.nome);
    if (p.estoque_baixo && p.ativo) {
      const selo = document.createElement("span");
      selo.className = "selo selo-baixo";
      selo.textContent = "estoque baixo";
      tdNome.appendChild(selo);
    }
    if (!p.ativo) {
      const selo = document.createElement("span");
      selo.className = "selo selo-inativo";
      selo.textContent = "inativo";
      tdNome.appendChild(selo);
    }

    const tdAcoes = document.createElement("td");
    tdAcoes.appendChild(botao("Editar", "", () => editar(p)));
    if (p.ativo) {
      tdAcoes.appendChild(botao("Inativar", "btn-perigo", () => inativar(p)));
    } else {
      tdAcoes.appendChild(botao("Reativar", "", () => reativar(p)));
    }

    tr.append(
      tdNome,
      celula(p.categoria || "—"),
      celula(formatoReal.format(p.preco), "num"),
      celula(String(p.estoque), "num"),
      celula(String(p.estoque_minimo), "num"),
      tdAcoes
    );
    el.lista.appendChild(tr);
  }
}

// ------------------------------------------------------------- formulário
function limparFormulario() {
  el.form.reset();
  el.id.value = "";
  el.minimo.value = 5;
  el.titulo.textContent = "Novo produto";
  el.salvar.textContent = "Salvar";
  el.cancelar.hidden = true;
}

function editar(p) {
  el.id.value = p.id;
  el.nome.value = p.nome;
  el.categoria.value = p.categoria || "";
  el.preco.value = p.preco;
  el.estoque.value = p.estoque;
  el.minimo.value = p.estoque_minimo;
  el.titulo.textContent = "Editar produto";
  el.salvar.textContent = "Salvar alterações";
  el.cancelar.hidden = false;
  mostrarMensagem("");
  window.scrollTo({ top: 0, behavior: "smooth" });
  el.nome.focus();
}

function lerFormulario() {
  return {
    nome: el.nome.value.trim(),
    categoria: el.categoria.value.trim(),
    preco: el.preco.value === "" ? null : Number(el.preco.value),
    estoque: el.estoque.value === "" ? null : Number(el.estoque.value),
    estoque_minimo: el.minimo.value === "" ? null : Number(el.minimo.value),
  };
}

// validação no front-end (o back-end valida de novo: RNF04)
function validarFormulario(d) {
  if (!d.nome) return "Informe o nome do produto.";
  if (d.preco === null || !(d.preco > 0)) return "O preço deve ser maior que zero.";
  if (d.estoque === null || !Number.isInteger(d.estoque) || d.estoque < 0)
    return "O estoque deve ser um número inteiro, zero ou maior.";
  if (d.estoque_minimo !== null && (!Number.isInteger(d.estoque_minimo) || d.estoque_minimo < 0))
    return "O estoque mínimo deve ser um número inteiro, zero ou maior.";
  return null;
}

el.form.addEventListener("submit", async (evento) => {
  evento.preventDefault();
  const dados = lerFormulario();
  const problema = validarFormulario(dados);
  if (problema) { mostrarMensagem(problema, "erro"); return; }

  const editando = el.id.value !== "";
  try {
    await api(editando ? "/produtos/" + el.id.value : "/produtos", {
      method: editando ? "PUT" : "POST",
      body: JSON.stringify(dados),
    });
    mostrarMensagem(editando ? "Produto atualizado." : "Produto cadastrado.", "ok");
    limparFormulario();
    carregar();
  } catch (e) {
    mostrarMensagem(e.message, "erro");
  }
});

el.cancelar.addEventListener("click", () => { limparFormulario(); mostrarMensagem(""); });

// ------------------------------------------------------------- inativar / reativar
async function inativar(p) {
  if (!confirm(`Inativar o produto "${p.nome}"?`)) return;
  try {
    await api("/produtos/" + p.id, { method: "DELETE" });
    mostrarMensagem("Produto inativado.", "ok");
    carregar();
  } catch (e) {
    mostrarMensagem(e.message, "erro");
  }
}

async function reativar(p) {
  try {
    await api("/produtos/" + p.id, {
      method: "PUT",
      body: JSON.stringify({ ...p, ativo: true }),
    });
    mostrarMensagem("Produto reativado.", "ok");
    carregar();
  } catch (e) {
    mostrarMensagem(e.message, "erro");
  }
}

// ------------------------------------------------------------- busca e filtro
let espera;
el.busca.addEventListener("input", () => {
  clearTimeout(espera);
  espera = setTimeout(carregar, 300);   // espera o usuário parar de digitar
});
el.todos.addEventListener("change", carregar);

carregar();
