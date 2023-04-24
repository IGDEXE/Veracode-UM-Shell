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

New-VeracodeUser () {
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
}

Block-VeracodeUser () {
    # Email do usuario
    emailUsuario=$1

    # Faz o bloqueio
    urlAPI="https://api.veracode.com/api/authn/v2/users/$idUsuario?partial=true"
    http --auth-type=veracode_hmac PUT "$urlAPI" < ./Templates/block.json > resposta.json
    retornoAPI=$(cat resposta.json)
    rm -f resposta.json
    user_name=$(echo $retornoAPI | jq -r '.user_name')
    if [[ -n $user_name ]]; then
        echo "Usuario $user_name foi bloqueado"
    else
        echo "Não foi possivel bloquear: $emailUsuario" >&2
        return 1
    fi
}