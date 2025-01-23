#!/bin/bash
#
# description: Bash file to setup local AI services
#
# author: Peter Schmalfeldt <me@peterschmalfeldt.com>

make_header(){
  TEXT=$( echo $1 | tr '\n' ' ')
  echo -e "\n\033[48;5;22m  Local AI › $TEXT  \033[0m\n"
}

output(){
  TEXT=$( echo $1 | tr '\n' ' ')
  echo -e "\033[7m › \033[27m $TEXT\n"
}

success(){
  TEXT=$( echo $1 | tr '\n' ' ')
  echo -e "\033[38;5;34m✓ Local AI › $TEXT\033[0m\n"
}

notice(){
  TEXT=$( echo $1 | tr '\n' ' ')
  echo -e "\033[38;5;220m→ Local AI › $TEXT\033[0m\n"
}

error(){
  TEXT=$( echo $1 | tr '\n' ' ')
  echo -e "\033[38;5;196m× Local AI › $TEXT\033[0m\n"
}

confirm(){
  echo -ne "\n\033[38;5;220m⚠ Local AI › $1\033[0m"
}

init_macos() {
  make_header "Initializing macOS"

  # Run Ollama Config
  ollama_config

  # Detect Ollama CLI
  ol=$(which ollama 2>/dev/null)

  # Detect Homebrew CLI
  br=$(which brew 2>/dev/null)

  output "Checking for Ollama..."

  if [ ! -z "$ol" ]; then
    success "Ollama CLI already installed"
  elif [ ! -z "$br" ]; then
    output "Installing Ollama via Homebrew"
    brew update
    brew install ollama

    output "Cleanup Homebrew"
    brew cleanup

    output "Starting Ollama Service"
    brew services start ollama
  else
    output "Downloading Ollama"
    curl https://ollama.com/download/Ollama-darwin.zip -L -o Ollama-darwin.zip
    unzip Ollama-darwin.zip
    sudo mv ./Ollama.app /Applications/Ollama.app
    rm -rf Ollama-darwin.zip
  fi

  output "Checking for AnythingLLM..."

  if [ -e "/Applications/AnythingLLM.app" ] then
    success "AnythingLLM already installed"
  elif [ ! -z "$br" ]; then
    output "Installing AnythingLLM via Homebrew"
    brew update
    brew install --cask anythingllm

    output "Cleanup Homebrew"
    brew cleanup
  else
    if [[ $(uname -m) == 'arm64' ]]; then
      output "Downloading AnythingLLM for Apple Silicon"
      curl https://cdn.useanything.com/latest/AnythingLLMDesktop-Silicon.dmg -L -o AnythingLLMDesktop-Silicon.dmg
      open AnythingLLMDesktop-Silicon.dmg
    else
      output "Downloading AnythingLLM for Apple Intel"
      curl https://cdn.useanything.com/latest/AnythingLLMDesktop.dmg -L -o AnythingLLMDesktop.dmg
      open AnythingLLMDesktop.dmg
    fi

    notice "Please install AnythingLLM manually from the mounted disk image."
  fi
}

init_ubuntu() {
  make_header "Initializing Ubuntu"

  # Run Ollama Config
  ollama_config

  ol=$(which ollama 2>/dev/null)

  output "Checking for Ollama..."
  
  if [ ! -z "$ol" ]; then
    success "Ollama CLI already installed"
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi

  # Restart Ollama Service
  systemctl daemon-reload
  systemctl restart ollama
}

ollama_config() {
  make_header "Configuring Ollama"

  # Define where we want to store Ollama Models
  notice "The path to the models directory?"
  read -p "Directory (leave blank to use default): " MODEL_DIR
  echo ""
  
  # Add Ollama Model Path to ZSH
  if [ -f ~/.zshrc ]; then
    output "Updating ZSH Profile"

    ZSH_CONFIG="\n# Ollama Settings"
    ZSH_CONFIG="$ZSH_CONFIG\nexport OLLAMA_DEBUG=1"
    ZSH_CONFIG="$ZSH_CONFIG\nexport OLLAMA_KEEP_ALIVE=-1"
    ZSH_CONFIG="$ZSH_CONFIG\nexport OLLAMA_ORIGINS=\"*\""

    if [ ! -z "$MODEL_DIR" ]; then
      ZSH_CONFIG="$ZSH_CONFIG\nexport OLLAMA_MODELS=\"$MODEL_DIR\""
    fi

    echo -e $ZSH_CONFIG >> ~/.zshrc
    zsh -c "source ~/.zshrc"
  fi

  # Add Ollama Model Path to BASH
  if [ -f ~/.bashrc ]; then
    output "Updating Bash Profile"

    BASH_CONFIG="\n# Ollama Settings"
    BASH_CONFIG="$BASH_CONFIG\nexport OLLAMA_DEBUG=1"
    BASH_CONFIG="$BASH_CONFIG\nexport OLLAMA_KEEP_ALIVE=-1"
    BASH_CONFIG="$BASH_CONFIG\nexport OLLAMA_ORIGINS=\"*\""

    if [ ! -z "$MODEL_DIR" ]; then
      BASH_CONFIG="$BASH_CONFIG\nexport OLLAMA_MODELS=\"$MODEL_DIR\""
    fi

    echo -e $BASH_CONFIG >> ~/.bashrc
    bash -c "source ~/.bashrc"
  fi

    # Add Ollama Model Path to SH
  if [ -f ~/.profile ]; then
    output "Updating Shell Profile"

    SH_CONFIG="\n# Ollama Settings"
    SH_CONFIG="$SH_CONFIG\nexport OLLAMA_DEBUG=1"
    SH_CONFIG="$SH_CONFIG\nexport OLLAMA_KEEP_ALIVE=-1"
    SH_CONFIG="$SH_CONFIG\nexport OLLAMA_ORIGINS=\"*\""

    if [ ! -z "$MODEL_DIR" ]; then
      SH_CONFIG="$SH_CONFIG\nexport OLLAMA_MODELS=\"$MODEL_DIR\""
    fi

    echo -e $SH_CONFIG >> ~/.profile
    sh -c "source ~/.profile"
  fi

  # Add Ollama Model Path to FISH
  if [ -f ~/.config/fish/config.fish ]; then
    output "Updating Fish Profile"
    
    FISH_CONFIG="\n# Ollama Settings"
    FISH_CONFIG="$FISH_CONFIG\nset -gx OLLAMA_DEBUG 1"
    FISH_CONFIG="$FISH_CONFIG\nset -gx OLLAMA_KEEP_ALIVE -1"
    FISH_CONFIG="$FISH_CONFIG\nset -gx OLLAMA_ORIGINS \"*\""

    if [ ! -z "$MODEL_DIR" ]; then
      FISH_CONFIG="$FISH_CONFIG\nset -gx OLLAMA_MODELS \"$MODEL_DIR\""
    fi
    
    echo -e $FISH_CONFIG >> ~/.config/fish/config.fish
    fish -c "source ~/.config/fish/config.fish"
  fi
}

ollama_load_model() {
  output "Create Local Model"
  ollama create local.ai -f ./local-al.modelfile

  output "Pull Embedding Model for RAG"
  ollama pull mxbai-embed-large

  output "Start Local AI Model"
  ollama run local.ai
}

# Check if we are on macOS
if [[ $OSTYPE == darwin* ]]; then
  init_macos
elif [[ $OSTYPE == linux* ]]; then
  if [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    if [[ $DISTRIB_ID == "Ubuntu" ]]; then
      init_ubuntu
    fi
  fi
else
  error "Unknown OS"
  exit 1
fi
