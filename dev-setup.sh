#!/bin/bash
set -e

# Configuration
USER_NAME="Cyber-arghya"
USER_EMAIL="work.arghya01@gmail.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SETUP] $1${NC}"
}

function install_basics() {
    log "Updating apt and installing basic tools..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget zip unzip coreutils
}

function install_build_tools() {
    log "Installing Build Essentials (C/C++)..."
    sudo apt install -y build-essential
}

function install_python_env() {
    log "Installing Python environment..."
    sudo apt install -y python3 python3-pip python3-venv
}

function install_git_suite() {
    log "Installing and configuring Git..."
    sudo apt install -y git

    # Configuration
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"
    git config --global init.defaultBranch main

    # Aliases
    git config --global alias.s "status"
    git config --global alias.a "add ."
    git config --global alias.cm "commit -m"
    git config --global alias.co "checkout"
    git config --global alias.br "branch"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.unstage "restore --staged"
    git config --global alias.undo "reset --soft HEAD~1"
    git config --global alias.hist "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all"
    git config --global alias.publish '!gh repo create --public --push --source=.'
    git config --global alias.ignored "!git status --ignored -s | grep '!!'"
    git config --global alias.why "check-ignore -v"

    # Global Gitignore
    local GITIGNORE_FILE="$HOME/.gitignore_global"
    cat <<'EOL' > "$GITIGNORE_FILE"
# =========================
# OPERATING SYSTEMS
# =========================
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Windows
Thumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk

# Linux
*~
.fuse_hidden*
.directory
.Trash-*

# =========================
# EDITORS & IDES
# =========================
.vscode/
.idea/
*.swp
*.swo
*.sublime-workspace
*.sublime-project
.settings/
.classpath
.project
*.iml

# =========================
# LOGS & DATABASES
# =========================
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
*.sqlite
*.sqlite3
*.db
dump.rdb

# =========================
# LANGUAGES
# =========================
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
env/
.pytest_cache/

# Node.js
node_modules/
dist/
build/
.next/
.nuxt/
coverage/
.npm/

# C / C++
*.o
*.obj
*.exe
*.out
a.out
*.dll
*.so
*.dylib
bin/
obj/
x64/
x86/
cmake-build-*/
CMakeFiles/
CMakeCache.txt

# Java
*.class
*.jar
*.war
*.ear

# Rust
target/

# Go
bin/

# =========================
# MISC / SECURITY
# =========================
# Archives (optional: remove if you track zips)
*.zip
*.tar
*.tar.gz
*.rar
*.7z

# Environment Variables (CRITICAL)
.env
.env.*
!.env.example
EOL
    git config --global core.excludesfile "$GITIGNORE_FILE"
}


function install_node_nvm() {
    log "Installing NVM and Node.js..."
    
    # Define NVM directory
    export NVM_DIR="$HOME/.nvm"
    
    # Check if NVM is already installed
    if [ ! -d "$NVM_DIR" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi

    # Load NVM for this session
   [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # Install LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
}



function setup_ssh_key() {
    log "Setting up SSH key..."
    if [ ! -f "$SSH_KEY_PATH" ]; then
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add "$SSH_KEY_PATH" 2>/dev/null
        cat "$SSH_KEY_PATH.pub"
        echo "Add the above key to your GitHub account."
    else
        log "SSH key already exists."
    fi
}


function setup_shell_utils() {
    log "Configuring aliases and custom functions..."
    
    # We will write to .bash_aliases instead of cluttering .bashrc
    # Ubuntu loads this file automatically if it exists.
    local ALIAS_FILE="$HOME/.bash_aliases"

    # Create/Overwrite the file with your specific configuration
    cat <<'EOF' > "$ALIAS_FILE"


# ==========================================
#           MY CUSTOM ALIASES
# ==========================================




# --- 1. Navigation & Listing ---
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias ~='cd ~'
alias home='cd ~'
alias ll='ls -alF'        # Full list with formatting
alias la='ls -A'          # All files including hidden
alias l='ls -CF'          # Compact view
alias dir='ls -alF'       # For Windows users used to typing 'dir'
alias tree='tree -I ".git"'


# --- 2. Safety First (Ask before deleting/overwriting) ---
alias mv='mv -i'          # Ask before moving over a file
alias cp='cp -i'          # Ask before copying over a file
alias ln='ln -i'          # Ask before linking over a file
alias rm='rm -i'          # Ask before deleting a file (Lifesaver!)

# --- 3. Git Workflow (The Essentials) ---
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'
alias gcl='git clone'
alias untrack='git rm --cached'
alias unstage='git restore --staged'
alias undo='git reset --soft HEAD~1'
alias hist='git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)" --all'
alias publish='gh repo create --public --push --source=.'
alias ignored='!git status --ignored -s | grep "!!"'
alias why='check-ignore -v'


# --- 4. Python & Development ---
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv venv'   # Create a venv easily
alias act='source venv/bin/activate' # Activate venv (if named 'venv')
alias deact='deactivate'             # Deactivate venv

# --- 5. System Maintenance ---
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias df='df -h'          # Disk space in readable format (GB/MB)
alias free='free -m'      # RAM usage in MB


# --- 6. Search & Grep ---
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# --- 7. Networking ---
alias myip='curl ifconfig.me'  # Shows your public IP address
alias ports='netstat -tulanp'  # Shows open ports


# --- 8. WSL Specific (Windows Integration) ---
# Opens the current Linux folder in Windows File Explorer
alias open='explorer.exe .'
# Shuts down WSL completely (run this if WSL acts buggy)
alias wslshutdown='wsl.exe --shutdown'


# Usage: newrepof my-project-name
function newrepof() {
    # 1. Check if a name was provided
    if [ -z "$1" ]; then
        echo "Error: Please provide a name for your project."
        return 1
    fi

    # 2. Create the folder and go inside
    mkdir -p "$1"
    cd "$1" || return

    # 3. Create a README and Setup Git
    echo "# $1" > README.md
    git init
    git add .
    git commit -m "Initial commit"

    # 4. Create the repo on GitHub and Push
    # Ensure gh is authenticated before running this
    if command -v gh &> /dev/null; then
         gh repo create "$1" --public --push --source=.
         echo "------------------------------------------------"
         echo "Done! Project '$1' is live on GitHub."
    else
         echo "Warning: GitHub CLI (gh) not found. Skipping repo creation."
    fi
    
    # 5. Open VS Code in this folder
    if command -v code &> /dev/null; then
        echo "Opening VS Code..."
        code .
    fi
}









# Universal Run: Checks permission once, then runs forever.
function run() {
    local f="$1"
    
    # 1. Validation
    [ -z "$f" ] && { echo "Usage: run <filename>"; return 1; }
    [ ! -f "$f" ] && { echo -e "${RED}File not found!${NC}"; return 1; }

    local ext="${f##*.}"
    local base="${f%.*}"

    # 2. Smart Logic based on file type
    case "$ext" in
        c)   
            # C needs compiling, output gets permission automatically by GCC
            gcc -Wall -Wextra -pthread "$f" -o "$base.out" && ./"$base.out" 
            ;;
        
        cpp) 
            # C++ needs compiling (C++23)
            g++ -Wall -Wextra -pthread -std=c++23 "$f" -o "$base.out" && ./"$base.out" 
            ;;
        
        py)  python3 "$f" ;;
        
        js)  node "$f" ;;
        
        sh)  
            # Check if executable? If NOT, apply chmod (One time only)
            [ ! -x "$f" ] && chmod +x "$f"
            ./"$f" 
            ;;
            
        *)   echo -e "${RED}Unsupported: .$ext${NC}"; return 1 ;;
    esac
}



#publish all file to git repo with folder name 
gpub() {
    # Initialize git if not present, then commit and push via gh cli
    [ -d .git ] || git init
    
    local repo_name=$(basename "$PWD")
    git add . && git commit -m "Initial commit"
    
    # Create public repo and push current directory
    gh repo create "$repo_name" --public --source=. --push && \
    echo "✅ $repo_name is now live!"
}

#update the git repo 
gup() {
    # Exit if not a git repo
    [ -d .git ] || { echo "❌ Error: Not a Git repo."; return 1; }

    git add .
    
    # Commit with provided message or "Updates", then push if commit succeeds
    if git commit -m "${1:-Updates}"; then
        git push && echo "✅ Success: Pushed to GitHub!"
    else
        echo "⚠️ No changes to commit."
    fi
}


EOF
    log "Aliases and newrepof updated in $ALIAS_FILE."
}


setup_nopasswd_sudo() {
    # 1. Determine target user (Argument $1 or default to current user)
    local target_user="${1:-$(whoami)}"
    local config_file="/etc/sudoers.d/${target_user}-nopasswd"

    echo "[-] Configuring passwordless sudo for: $target_user"

    # 2. Write the configuration (Requires sudo access initially)
    # Uses tee to write to restricted directory
    echo "$target_user ALL=(ALL) NOPASSWD:ALL" | sudo tee "$config_file" > /dev/null

    # 3. Set strict permissions (0440 = Read-only for Owner/Group)
    sudo chmod 0440 "$config_file"

    # 4. Verify functionality
    # sudo -k resets the timestamp, sudo -n checks non-interactive access
    sudo -k
    if sudo -n true 2>/dev/null; then
        echo "[+] Success: Sudo is now passwordless."
    else
        echo "[!] Error: Something went wrong. Password still required."
    fi
}


function install_gh_cli() {
    log "Checking GitHub CLI..."
    if ! command -v gh &> /dev/null; then
        log "Installing GitHub CLI..."
        local KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
        sudo mkdir -p -m 755 $(dirname $KEYRING)
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee $KEYRING > /dev/null
        sudo chmod go+r $KEYRING
        echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install -y gh
    else
        log "GitHub CLI is already installed."
    fi

    # ONLY login if not already authenticated
    if ! gh auth status &> /dev/null; then
        log "Not logged into GitHub. Starting login..."
        gh auth login
    else
        log "Already authenticated with GitHub CLI. Skipping login."
        gh auth status
    fi
}


function show_summary() {
    echo -e "\n${GREEN}=========================================="
    echo -e "         INSTALLATION SUMMARY"
    echo -e "==========================================${NC}"
    
    # Check versions for specific dev tools
    echo -e "Git:      $(git --version | awk '{print $3}')"
    echo -e "Python:   $(python3 --version | awk '{print $2}')"
    
    # Load NVM to check Node if it was just installed
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    echo -e "Node:     $(node -v)"
    echo -e "NPM:      $(npm -v)"
    echo -e "GH CLI:   $(gh --version | head -n 1 | awk '{print $3}')"
    
    echo -e "=========================================="
    echo -e "Setup Complete! Run 'source ~/.bashrc' to activate aliases."
}

# --- Execution ---   chmod +x dev-setup.sh 
#                     ./dev-setup.sh source 
#                     ~/.bashrc 
setup_nopasswd_sudo
setup_shell_utils
install_basics
install_build_tools
install_python_env
install_node_nvm
install_git_suite
setup_ssh_key
install_gh_cli
show_summary