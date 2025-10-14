#!/bin/bash

# Script to set up Apache reverse proxy for ggwave-bible.thirdwavesoft.com
# Run this on the server: ssh starwave@192.168.1.111 'bash -s' < setup-reverse-proxy.sh

DOMAIN="ggwave-bible.thirdwavesoft.com"
CONFIG_FILE="/etc/apache2/sites-available/000-default.conf"

echo "🔧 Setting up Apache reverse proxy for ${DOMAIN}..."

# Backup existing configuration
echo "📋 Backing up existing Apache configuration..."
sudo cp ${CONFIG_FILE} ${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)

# Add new VirtualHost configuration before the last line (vim comment)
echo "📝 Adding VirtualHost configuration..."
sudo sed -i '/# vim: syntax=apache/i \
<VirtualHost *:80>\
    ServerName ggwave-bible.thirdwavesoft.com\
    ProxyPreserveHost On\
    ProxyPass / http://localhost:3000/\
    ProxyPassReverse / http://localhost:3000/\
RewriteEngine on\
RewriteCond %{SERVER_NAME} =ggwave-bible.thirdwavesoft.com\
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]\
</VirtualHost>\
<VirtualHost *:443>\
    ServerName ggwave-bible.thirdwavesoft.com\
    SSLEngine on\
    SSLCertificateFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/fullchain.pem\
    SSLCertificateKeyFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/privkey.pem\
    ProxyPreserveHost On\
    ProxyPass / http://localhost:3000/\
    ProxyPassReverse / http://localhost:3000/\
</VirtualHost>\
' ${CONFIG_FILE}

echo "✅ Configuration added to ${CONFIG_FILE}"

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-apache
fi

# Obtain SSL certificate using certbot
echo "🔐 Obtaining SSL certificate for ${DOMAIN}..."
echo "⚠️  Make sure DNS for ${DOMAIN} points to this server (192.168.1.111)"
read -p "Press Enter to continue with SSL certificate setup, or Ctrl+C to cancel..."

sudo certbot --apache -d ${DOMAIN} --non-interactive --agree-tos --email webmaster@thirdwavesoft.com

# Test Apache configuration
echo "🧪 Testing Apache configuration..."
sudo apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
    echo "🔄 Reloading Apache..."
    sudo systemctl reload apache2
    echo "✅ Apache reloaded successfully!"
    echo ""
    echo "🎉 Setup complete!"
    echo "🌐 Your app should now be accessible at:"
    echo "   - http://${DOMAIN} (redirects to HTTPS)"
    echo "   - https://${DOMAIN}"
else
    echo "❌ Apache configuration test failed!"
    echo "   Restoring backup..."
    sudo cp ${CONFIG_FILE}.backup.* ${CONFIG_FILE}
    exit 1
fi
