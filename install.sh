#!/bin/bash

trap "echo ''; echo '🛑 Script interrupted safely. SSH is still alive.'; exit 0" SIGINT

RED='\033[1;31m'
DARK_RED='\033[0;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

# -------- BIG LOGO --------
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

    echo -e "${WHITE}[*] Entering maintenance mode...${RESET}"
    php artisan down

    echo -e "${WHITE}[*] Creating backup...${RESET}"
    tar -czf "panel-backup-$(date +%F-%T).tar.gz" ./

    echo -e "${WHITE}[*] Downloading latest panel release...${RESET}"
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv

    echo -e "${WHITE}[*] Setting permissions...${RESET}"
    chmod -R 755 storage/ bootstrap/cache

    echo -e "${WHITE}[*] Installing composer dependencies...${RESET}"
    composer install --no-dev --optimize-autoloader

    echo -e "${WHITE}[*] Clearing view and config cache...${RESET}"
    php artisan view:clear
    php artisan config:clear

    echo -e "${WHITE}[*] Running database migrations...${RESET}"
    php artisan migrate --seed --force

    echo -e "${WHITE}[*] Setting ownership...${RESET}"
    chown -R www-data:www-data "$PANEL_DIR"

    echo -e "${WHITE}[*] Restarting queue workers...${RESET}"
    php artisan queue:restart

    echo -e "${WHITE}[*] Exiting maintenance mode...${RESET}"
    php artisan up

    echo -e "${RED}[✔] Pterodactyl Panel update completed successfully!${RESET}"
}

# -------- MENU --------
while true; do
    show_logo

    echo -e "${RED}[1]${WHITE} 🔄 Update System"  
    echo -e "${RED}[2]${WHITE} ⚙️ Install Panel"  
    echo -e "${RED}[3]${WHITE} 🦅 Update Wings"  
    echo -e "${RED}[4]${WHITE} 📦 Update Panel"  
    echo -e "${RED}[0]${WHITE} ❌ Exit"  
    echo ""  

    read -p "👉 Choose option: " choice  

    case $choice in  
        1) update_system ;;  
        2) install_panel ;;  
        3) update_wings ;;  
        4) update_panel ;;  
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
