#!/bin/bash
set -e

# Lista de funcoes
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

Get-VeracodeRoles () {
    # Nome do cargo conforme estabelecido no template
    tipoFuncionario=$1
    # Carrega o Template
    templateRoles=$(cat ./Templates/exemploRoles.json)
    # Valida as roles pelo cargo
    shopt -s nocasematch
    case $tipoFuncionario in
        Desenvolvedor)
            roles=$(echo $templateRoles | jq -r '.rolesDev')
            ;;
        QA)
            roles=$(echo $templateRoles | jq -r '.rolesQa')
            ;;
        SOC)
            roles=$(echo $templateRoles | jq -r '.rolesSoc')
            ;;
        DEVOPS)
            roles=$(echo $templateRoles | jq -r '.rolesSRE')
            ;;
        BLUETEAM)
            roles=$(echo $templateRoles | jq -r '.rolesBlueTeam')
            ;;
        *)
            echo "Não foi encontrado nenhum perfil para $tipoFuncionario" >&2
            return 1
            ;;
    esac
    # Retorna as roles
    echo $roles
}

# Parametros
emailUsuario=$1
tipoFuncionario=$2

# Recebe os valores
idUsuario=$(Get-VeracodeUserID $emailUsuario)
roles=$(Get-VeracodeRoles $tipoFuncionario)

# Atualiza as roles com base no modelo
templateRoles=$(cat ./Templates/extruturaRoles.json | jq -r '.roles')
nome_arquivo=$(date +'RESP%Y%m%d_%H%M%S.json')
urlAPI="https://api.veracode.com/api/authn/v2/users/$idUsuario?partial=true"
http --auth-type=veracode_hmac PUT "$urlAPI" < $roles > $nome_arquivo