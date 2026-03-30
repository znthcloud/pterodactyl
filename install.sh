#!/bin/bash

# 🛑 Handle Ctrl + C safely
trap "echo ''; echo '🛑 Script interrupted safely. SSH is still alive.'; exit 0" SIGINT

set -e

clear
echo "========================================"
echo "   Zenith Cloud™ Ultimate Manager"
echo "========================================"
echo ""

# -------- SYSTEM UPDATE --------
echo "🔄 Updating system packages..."
apt update && apt upgrade -y && apt dist-upgrade -y

echo "📦 Installing required packages..."
apt install -y curl wget git unzip tar sudo neofetch software-properties-common ca-certificates lsb-release apt-transport-https

# -------- MOTD (silent, no announcement) --------
chmod -x /etc/update-motd.d/* 2>/dev/null || true

cat << 'EOF' > /etc/update-motd.d/00-zenithcloud
#!/bin/bash

GREEN="\e[38;5;82m"
CYAN="\e[38;5;51m"
BLUE="\e[38;5;39m"
MAGENTA="\e[38;5;213m"
YELLOW="\e[38;5;220m"
GRAY="\e[38;5;245m"
RESET="\e[0m"

HOSTNAME=$(hostname)
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(awk '{print $1}' /proc/loadavg)

MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PERC=$((MEM_USED * 100 / MEM_TOTAL))

DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

IP=$(hostname -I | awk '{print $1}')
USERS=$(who | wc -l)
PROCS=$(ps -e --no-headers | wc -l)

echo ""

echo -e "${BLUE}"
cat << "LOGO"
███████╗███████╗███╗   ██╗██╗████████╗██╗  ██╗
╚══███╔╝██╔════╝████╗  ██║██║╚══██╔══╝██║  ██║
  ███╔╝ █████╗  ██╔██╗ ██║██║   ██║   ███████║
 ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║   ██╔══██║
███████╗███████╗██║ ╚████║██║   ██║   ██║  ██║
╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝  ╚═╝
LOGO
echo -e "${RESET}"

echo -e "${GREEN}🚀 Welcome to ${BLUE}Zenith${RESET}${GREEN} Cloud Infrastructure${RESET}"
echo -e "${BLUE}Ultra Performance • DDoS Protected • 24/7 Uptime${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

printf "${CYAN}%-18s${RESET} %s\n" "Hostname:" "$HOSTNAME"
printf "${CYAN}%-18s${RESET} %s\n" "Operating System:" "$OS"
printf "${CYAN}%-18s${RESET} %s\n" "Kernel:" "$KERNEL"
printf "${CYAN}%-18s${RESET} %s\n" "Uptime:" "$UPTIME"
printf "${CYAN}%-18s${RESET} %s\n" "CPU Load:" "$LOAD"
printf "${CYAN}%-18s${RESET} %sMB / %sMB (${YELLOW}%s%%${RESET})\n" "Memory:" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERC"
printf "${CYAN}%-18s${RESET} %s\n" "Disk Usage:" "$DISK"
printf "${CYAN}%-18s${RESET} %s\n" "Processes:" "$PROCS"
printf "${CYAN}%-18s${RESET} %s\n" "Users Online:" "$USERS"
printf "${CYAN}%-18s${RESET} %s\n" "IP Address:" "$IP"

echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo -e "${GREEN}Support:${RESET}  Zenith Cloud"
echo -e "${GREEN}Discord:${RESET}  https://zenithcloud.gg"
echo -e "${GREEN}Website:${RESET}  https://web.zenithcloud.fun"
echo -e "${MAGENTA}${BLUE}Zenith${RESET}${MAGENTA} Cloud — Peak Performance ⚡${RESET}"
echo ""
EOF

chmod +x /etc/update-motd.d/00-zenithcloud

# -------- INSTALL PANEL --------
read -p "⚙️ Install Pterodactyl Panel? (y/n): " install_choice

if [[ "$install_choice" =~ ^[Yy]$ ]]; then
    bash <(curl -s https://pterodactyl-installer.se)
fi

# -------- WINGS UPDATE --------
read -p "🦅 Update Wings? (y/n): " wings_choice

if [[ "$wings_choice" =~ ^[Yy]$ ]]; then
    systemctl stop wings

    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"

    chmod u+x /usr/local/bin/wings
    systemctl restart wings
fi

# -------- PANEL UPDATE --------
read -p "📦 Update Panel? (y/n): " panel_choice

if [[ "$panel_choice" =~ ^[Yy]$ ]]; then
    cd /var/www/pterodactyl || exit

    php artisan down

    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv

    chmod -R 755 storage/* bootstrap/cache

    composer install --no-dev --optimize-autoloader

    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force

    chown -R www-data:www-data /var/www/pterodactyl/*
    php artisan queue:restart
    php artisan up

    systemctl restart nginx
    systemctl restart redis
    systemctl restart mysql
fi

echo ""
echo "========================================"
echo "🎯 Zenith Cloud™ All Tasks Completed!"
echo "========================================"
