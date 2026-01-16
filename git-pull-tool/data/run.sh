#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# shellcheck disable=SC2034
CONFIG_PATH=/data/options.json
# HOME=~

bashio::log.info "Starting GitPuller Add-on"

GENERAL_PRIVATE_KEY=$(bashio::config 'general_private_key')
GENERAL_KEY_PROTOCOL=$(bashio::config 'general_key_protocol')
REPOSITORIES=$(bashio::config 'repos')

# bashio::log.info "GENERAL_PRIVATE_KEY is set to ${GENERAL_PRIVATE_KEY}"
bashio::log.info "GENERAL_KEY_PROTOCOL is set to ${GENERAL_KEY_PROTOCOL}"
bashio::log.info "REPOSITORIES is set to ${REPOSITORIES}"

# Fork from https://github.com/home-assistant/addons/tree/master/git_puller/data/run.sh
function add_gen_ssh_key {
    bashio::log.info "[Info] Start adding SSH key"
    mkdir -p "${HOME}/.ssh"

    (
        echo "Host *"
        echo "    StrictHostKeyChecking no"
    ) > "${HOME}/.ssh/config"

    bashio::log.info "[Info] Setup deployment_key on id_${GENERAL_KEY_PROTOCOL}"
    rm -f "${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"
    
    # Write the private key, interpreting \n as actual newlines
    echo -e "$GENERAL_PRIVATE_KEY" > "${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"

    chmod 600 "${HOME}/.ssh/config"
    chmod 600 "${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"

    bashio::log.info "[Info] SSH key written to ${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"
    ls -la "${HOME}/.ssh/"
}

function git_sync_repository {
  pwd
  echo "Listing contents of2 ${HOME}/.ssh/"
  ls -la "${HOME}/.ssh/"

  local REPOSITORY=$1
  local GIT_BRANCH=$2
  local DESTINATION_DIR=$3
  local GIT_REMOTE=${4:-origin}
  
  # Convert HTTP/HTTPS URLs to SSH format if SSH keys are configured
  if [[ "$REPOSITORY" =~ ^https?://([^/]+)/(.+)$ ]]; then
    local HOST="${BASH_REMATCH[1]}"
    local PATH="${BASH_REMATCH[2]}"
    REPOSITORY="git@${HOST}:${PATH}"
    bashio::log.info "[Info] Converted HTTP/HTTPS URL to SSH format: $REPOSITORY"
  fi
  
  # Extract repository name from URL
  REPO_NAME=$(basename "$REPOSITORY" .git)
  REPO_PATH="${DESTINATION_DIR}/${REPO_NAME}"
  
  bashio::log.info "[Info] Repository: $REPOSITORY"
  bashio::log.info "[Info] Branch: $GIT_BRANCH"
  bashio::log.info "[Info] Destination: $REPO_PATH"
  bashio::log.info "[Info] Remote: $GIT_REMOTE"
  
  # Create destination directory if it doesn't exist
  mkdir -p "$DESTINATION_DIR" || bashio::exit.nok "[Error] Failed to create destination directory: $DESTINATION_DIR"
  
  if [ -d "$REPO_PATH/.git" ]; then
    # Repository exists, do git pull
    bashio::log.info "[Info] Repository exists, performing git pull"
    cd "$REPO_PATH" || bashio::exit.nok "[Error] Failed to change to directory: $REPO_PATH"
    
    git fetch "$GIT_REMOTE" || bashio::exit.nok "[Error] Git fetch failed"
    git checkout "$GIT_BRANCH" || bashio::exit.nok "[Error] Git checkout branch failed"
    git pull "$GIT_REMOTE" "$GIT_BRANCH" || bashio::exit.nok "[Error] Git pull failed"
    
    bashio::log.info "[Info] Successfully pulled latest changes"
  else
  pwd
    echo "Listing contents of3 ${HOME}/.ssh/"
    ls -la "${HOME}/.ssh/"
    cat "${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"
    # Repository doesn't exist, do git clone
    bashio::log.info "[Info] Repository doesn't exist, performing git clone"
    
    # Set SSH command to use the configured key
    export GIT_SSH_COMMAND="ssh -i ${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  
    cat "${HOME}/.ssh/id_${GENERAL_KEY_PROTOCOL}"

    # GIT_TRACE=1 \
    # GIT_TRACE_PACKET=1 \
    # GIT_TRACE_PERFORMANCE=1 \
    # GIT_CURL_VERBOSE=1 \
    # GIT_SSH_COMMAND="ssh -vvv" \
    git clone -b "$GIT_BRANCH" "$REPOSITORY" "$REPO_PATH" 
    #|| bashio::exit.nok "[Error] Git clone failed"
    
    bashio::log.info "[Info] Successfully cloned repository"
  fi
}

function git_pull {
  bashio::log.info "[Info] Start git sync"

  while IFS= read -r jsonLine; do
    echo "Processing line: $jsonLine"
    REPOSITORY=$(jq -r '.repository' <<< "$jsonLine")
    GIT_BRANCH=$(jq -r '.git_branch' <<< "$jsonLine")
    DESTINATION_DIR=$(jq -r '.destination_dir' <<< "$jsonLine")
    GIT_REMOTE=$(jq -r '.git_remote' <<< "$jsonLine")

    bashio::log.info "[Info] Processing repository: $REPOSITORY on branch: $GIT_BRANCH into folder: $DESTINATION_DIR from remote: $GIT_REMOTE"
    
    git_sync_repository "$REPOSITORY" "$GIT_BRANCH" "$DESTINATION_DIR" "$GIT_REMOTE"
  done <<< "$REPOSITORIES"
}

#### Main run ####
add_gen_ssh_key
git_pull

while true; do
  sleep 600
done
##################