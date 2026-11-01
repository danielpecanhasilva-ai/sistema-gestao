// Função única para falar com a API (usada por todas as telas)
const API = "/api";

async function api(caminho, opcoes = {}) {
  const resposta = await fetch(API + caminho, {
    headers: { "Content-Type": "application/json" },
    ...opcoes,
  });

  let dados = null;
  try { dados = await resposta.json(); } catch (e) { /* resposta sem corpo */ }

  if (!resposta.ok) {
    const texto = dados && (dados.erros ? dados.erros.join(" ") : dados.erro);
    const erro = new Error(texto || "Erro ao falar com o servidor.");
    erro.status = resposta.status;
    throw erro;
  }
  return dados;
}
