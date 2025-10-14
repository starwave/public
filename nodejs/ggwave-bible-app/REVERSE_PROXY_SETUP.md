# Apache Reverse Proxy Setup for ggwave-bible.thirdwavesoft.com

## Prerequisites
1. DNS for `ggwave-bible.thirdwavesoft.com` should point to 192.168.1.111
2. Docker container is running on localhost:3000 (already done ✓)

## Manual Setup Steps

### 1. First, ensure DNS is configured
Check that the domain resolves to your server:
```bash
nslookup ggwave-bible.thirdwavesoft.com
```

### 2. SSH to the server
```bash
ssh starwave@192.168.1.111
```

### 3. Backup current Apache configuration
```bash
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup
```

### 4. Edit the Apache configuration
```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

Add these two VirtualHost blocks (before the `# vim:` line at the end):

```apache
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
```

Save and exit (Ctrl+X, Y, Enter)

### 5. Obtain SSL certificate with certbot
```bash
sudo certbot --apache -d ggwave-bible.thirdwavesoft.com
```

Follow the prompts. Certbot will automatically configure SSL.

### 6. Test Apache configuration
```bash
sudo apache2ctl configtest
```

Should return "Syntax OK"

### 7. Reload Apache
```bash
sudo systemctl reload apache2
```

### 8. Verify it's working
```bash
curl -I http://ggwave-bible.thirdwavesoft.com
curl -I https://ggwave-bible.thirdwavesoft.com
```

## Quick One-Liner (after DNS is configured)

If you want to skip manual editing, copy and run this on the server:

```bash
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup && \
sudo sed -i '/# vim: syntax=apache/i <VirtualHost *:80>\n    ServerName ggwave-bible.thirdwavesoft.com\n    ProxyPreserveHost On\n    ProxyPass / http://localhost:3000/\n    ProxyPassReverse / http://localhost:3000/\nRewriteEngine on\nRewriteCond %{SERVER_NAME} =ggwave-bible.thirdwavesoft.com\nRewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]\n</VirtualHost>\n<VirtualHost *:443>\n    ServerName ggwave-bible.thirdwavesoft.com\n    SSLEngine on\n    SSLCertificateFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/fullchain.pem\n    SSLCertificateKeyFile /etc/letsencrypt/live/ggwave-bible.thirdwavesoft.com/privkey.pem\n    ProxyPreserveHost On\n    ProxyPass / http://localhost:3000/\n    ProxyPassReverse / http://localhost:3000/\n</VirtualHost>\n' /etc/apache2/sites-available/000-default.conf && \
sudo certbot --apache -d ggwave-bible.thirdwavesoft.com && \
sudo apache2ctl configtest && \
sudo systemctl reload apache2
```

## Troubleshooting

If Apache reload fails:
```bash
sudo systemctl status apache2
sudo journalctl -xeu apache2
```

To restore backup:
```bash
sudo cp /etc/apache2/sites-available/000-default.conf.backup /etc/apache2/sites-available/000-default.conf
sudo systemctl reload apache2
```
