#!/bin/bash

trap "echo ''; echo '🛑 Script interrupted safely. SSH is still alive.'; exit 0" SIGINT
set -e

# -------- FUNCTIONS --------

update_system() {
    echo "🔄 Updating system..."
    apt update && apt upgrade -y && apt dist-upgrade -y

    echo "📦 Installing required packages..."
    apt install -y curl wget git unzip tar sudo neofetch software-properties-common ca-certificates lsb-release apt-transport-https
}

install_motd() {
    echo "🎨 Installing Zenith MOTD..."

    chmod -x /etc/update-motd.d/* 2>/dev/null || true

    cat << 'EOF' > /etc/update-motd.d/00-zenithcloud
#!/bin/bash
echo "🚀 Zenith Cloud Ready ⚡"
EOF

    chmod +x /etc/update-motd.d/00-zenithcloud
}

install_panel() {
    echo "⚙️ Installing Pterodactyl Panel..."
    bash <(curl -s https://pterodactyl-installer.se)
}

update_wings() {
    echo "🦅 Updating Wings..."
    systemctl stop wings

    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"

    chmod u+x /usr/local/bin/wings
    systemctl restart wings
}

update_panel() {
    echo "📦 Updating Panel..."

    cd /var/www/pterodactyl || return

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
}

# -------- MAIN MENU LOOP --------

while true; do
    clear
    echo "========================================"
    echo "   🚀 Zenith Cloud™ Ultimate Manager"
    echo "========================================"
    echo ""
    echo "1️⃣  Update System & Install Packages"
    echo "2️⃣  Install Zenith MOTD"
    echo "3️⃣  Install Pterodactyl Panel"
    echo "4️⃣  Update Wings"
    echo "5️⃣  Update Panel"
    echo "0️⃣  Exit"
    echo ""

    read -p "👉 Choose an option: " choice

    case $choice in
        1)
            update_system
            ;;
        2)
            install_motd
            ;;
        3)
            install_panel
            ;;
        4)
            update_wings
            ;;
        5)
            update_panel
            ;;
        0)
            echo "👋 Exiting Zenith Manager..."
            exit 0
            ;;
        *)
            echo "❌ Invalid option!"
            ;;
    esac

    echo ""
    read -p "⏎ Press Enter to return to menu..."
done
