#!/bin/bash
set -e
# Caminho do arquivo JSON com os dados para criar um novo usuario
caminhoJSON=$1

# Faz a chamada da API
http --auth-type=veracode_hmac PUT "https://api.veracode.com/api/authn/v2/users" < $caminhoJSON > resposta.json
retornoAPI=$(cat resposta.json)
#rm -f resposta.json
user_name=$(echo $retornoAPI | jq -r '.user_name')
if [ "$user_name" = "null" ]; then
    statusErro=$(echo $retornoAPI | jq -r '.http_status')
    codigoErro=$(echo $retornoAPI | jq -r '.http_code')
    mensagemErro=$(echo $retornoAPI | jq -r '.message')
    echo "Erro: $codigoErro - $statusErro" >&2
    echo "$mensagemErro" >&2
    return 1
    elif  [[ -n $user_name ]]; then
    echo "Usuario $user_name foi criado"
else
    echo "Erro ao criar o usuario" >&2
    return 1
fi