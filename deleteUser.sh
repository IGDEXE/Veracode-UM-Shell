#!/bin/bash
set -e
# Email do usuario
emailUsuario=$1

Get-VeracodeUserID () {
    emailUsuario=$1

    # Fazendo a requisição HTTP com httpie e armazenando a resposta em uma variável
    resposta=$(http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?size=1000")

    # Processando a resposta JSON com jq e filtrando a lista de usuários para encontrar o usuário com o nome especificado
    user_id=$(echo $resposta | jq -r '._embedded.users[] | select(.user_name == "'${emailUsuario}'") | .user_id')

    # Verificando se o usuário foi encontrado e exibindo uma mensagem de erro se não foi
    if [[ -n $user_id ]]; then
        echo $user_id
    else
        echo "Não foi encontrado ID para o usuário: $emailUsuario" >&2
        return 1
    fi
}

# Recebe o ID com base no nome
idUsuario=$(Get-VeracodeUserID $emailUsuario)

# Faz o bloqueio
http --auth-type=veracode_hmac DELETE "https://api.veracode.com/api/authn/v2/users/$idUsuario"