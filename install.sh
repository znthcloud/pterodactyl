#!/bin/bash

trap "echo ''; echo '🛑 Script interrupted safely. SSH is still alive.'; exit 0" SIGINT

RED='\033[1;31m'
DARK_RED='\033[0;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

# -------- LOGO --------
show_logo() {
    clear
    echo -e "${RED}"
    cat << "EOF"
███████╗███████╗███╗   ██╗██╗████████╗██╗  ██╗
╚══███╔╝██╔════╝████╗  ██║██║╚══██╔══╝██║  ██║
███╔╝ █████╗  ██╔██╗ ██║██║   ██║   ███████║
███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║   ██╔══██║
███████╗███████╗██║ ╚████║██║   ██║   ██║  ██║
╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝  ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "${WHITE}        ⚡ Z E N I T H   C L O U D ⚡${RESET}"
    echo -e "${DARK_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}        Owner: ANSH 👑 | Full Control Panel${RESET}"
    echo ""
}

# -------- FUNCTIONS --------
update_system() {
    echo -e "${RED}⚙️ Updating system...${RESET}"
    apt update && apt upgrade -y && apt dist-upgrade -y
}

install_panel() {
    echo -e "${RED}🚀 Installing Panel...${RESET}"
    bash <(curl -s https://pterodactyl-installer.se)
}

update_wings() {
    echo -e "${RED}🦅 Updating Wings...${RESET}"
    systemctl stop wings
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
}

update_panel() {
    PANEL_DIR="/var/www/pterodactyl"
    cd "$PANEL_DIR" || { echo -e "${DARK_RED}❌ Panel directory not found${RESET}"; return; }

    php artisan down
    tar -czf "panel-backup-$(date +%F-%T).tar.gz" ./
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/ bootstrap/cache
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data "$PANEL_DIR"
    php artisan queue:restart
    php artisan up

    echo -e "${RED}[✔] Panel updated successfully!${RESET}"
}

# -------- BLUEPRINT MENU --------
blueprint_menu() {
    while true; do
        clear
        echo -e "${RED}⚡ BLUEPRINT INSTALLER${RESET}"
        echo ""
        echo -e "${RED}[1]${WHITE} Install Blueprint Framework"
        echo -e "${RED}[2]${WHITE} Install Blueprint Addons"
        echo -e "${RED}[0]${WHITE} Back"
        echo ""

        read -p "👉 Choose option: " bp_choice

        case $bp_choice in
            1) install_blueprint ;;
            2) install_addons ;;
            0) break ;;
            *) echo -e "${DARK_RED}❌ Invalid option${RESET}" ;;
        esac

        read -p "⏎ Press Enter to continue..."
    done
}

# -------- BLUEPRINT FRAMEWORK --------
install_blueprint() {
    echo -e "${RED}🚀 Installing Blueprint Framework...${RESET}"

    cd /var/www/pterodactyl || { echo "Panel not found"; return; }

    apt update -y && apt upgrade -y
    apt install -y curl wget unzip git zip

    LATEST_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep browser_download_url | grep .zip | head -n 1 | cut -d '"' -f 4)

    wget -q "$LATEST_URL" -O blueprint.zip
    unzip -oq blueprint.zip
    rm -f blueprint.zip

    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    npm install -g corepack
    corepack enable

    yarn install
    chmod +x blueprint.sh
    bash blueprint.sh

    touch .blueprint-installed

    echo -e "${RED}[✔] Blueprint Installed Successfully!${RESET}"
}

# -------- BLUEPRINT ADDONS --------
install_addons() {
    echo -e "${RED}📦 Installing Blueprint Addons...${RESET}"

    mapfile -t FILES < <(ls *.blueprint 2>/dev/null)

    if (( ${#FILES[@]} == 0 )); then
        echo -e "${DARK_RED}❌ No .blueprint files found!${RESET}"
        return
    fi

    echo -e "${WHITE}Found ${#FILES[@]} files:${RESET}"
    for f in "${FILES[@]}"; do
        echo " - $f"
    done

    read -p "Install all? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return

    for f in "${FILES[@]}"; do
        echo -e "${RED}Installing $f...${RESET}"
        blueprint -install "$f"
    done

    echo -e "${RED}[✔] All addons installed!${RESET}"
}

# -------- MAIN MENU --------
while true; do
    show_logo

    echo -e "${RED}[1]${WHITE} 🔄 Update System"
    echo -e "${RED}[2]${WHITE} ⚙️ Install Panel"
    echo -e "${RED}[3]${WHITE} 🦅 Update Wings"
    echo -e "${RED}[4]${WHITE} 📦 Update Panel"
    echo -e "${RED}[5]${WHITE} 🎨 Blueprint Installer"
    echo -e "${RED}[0]${WHITE} ❌ Exit"
    echo ""

    read -p "👉 Choose option: " choice

    case $choice in
        1) update_system ;;
        2) install_panel ;;
        3) update_wings ;;
        4) update_panel ;;
        5) blueprint_menu ;;
        0)
            echo -e "${RED}👋 Exiting Zenith Cloud...${RESET}"
            break
            ;;
        *)
            echo -e "${DARK_RED}❌ Invalid option${RESET}"
            ;;
    esac

    echo ""
    read -p "⏎ Press Enter to continue..."
done
