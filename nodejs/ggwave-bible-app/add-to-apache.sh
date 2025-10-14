#!/bin/bash

# Simple script to add ggwave-bible virtualhost to Apache config
# SSH to server and run: bash add-to-apache.sh

echo "🔧 Adding ggwave-bible.thirdwavesoft.com to Apache configuration..."

# Backup
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup

# Add the configuration (using a temp file for clarity)
cat > /tmp/ggwave-bible-vhost.conf << 'EOF'
<VirtualHost *:80>
    ServerName ggwave-bible.thirdwavesoft.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
RewriteEngine on
RewriteCond %{SERVER_NAME} =ggwave-bible.thirdwavesoft.com
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
<VirtualHost *:443>
    ServerName ggwave-bible.thirdwavesoft.com
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/privkey.pem
    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
EOF

# Insert before the vim comment line
sudo sed -i '/# vim: syntax=apache/e cat /tmp/ggwave-bible-vhost.conf' /etc/apache2/sites-available/000-default.conf

echo "✅ Configuration added!"
echo ""
echo "📋 Current VirtualHosts:"
grep "ServerName" /etc/apache2/sites-available/000-default.conf

echo ""
echo "🔐 Now obtaining SSL certificate..."
sudo certbot --apache -d ggwave-bible.thirdwavesoft.com

echo ""
echo "🧪 Testing Apache configuration..."
sudo apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Configuration is valid!"
    echo "🔄 Reloading Apache..."
    sudo systemctl reload apache2
    echo ""
    echo "🎉 Done! Visit https://ggwave-bible.thirdwavesoft.com"
else
    echo "❌ Configuration error! Restoring backup..."
    sudo cp /etc/apache2/sites-available/000-default.conf.backup /etc/apache2/sites-available/000-default.conf
fi

# Cleanup
rm /tmp/ggwave-bible-vhost.conf
