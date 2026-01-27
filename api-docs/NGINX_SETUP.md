# AKURA SafeStride API - Nginx Setup Guide
# Last Updated: 2026-01-27

## Prerequisites
- Ubuntu/Debian server with sudo access
- Domain: api.akura.in pointing to your server IP
- Node.js and npm installed (for deployment scripts)

## Installation Steps

### 1. Install Nginx
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 2. Install Certbot (Let's Encrypt SSL)
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 3. Deploy API Documentation
Run the deployment script to generate the Swagger UI bundle:
```bash
cd /path/to/safestride/api-docs
bash ./deploy_api_docs.sh staging ./AKURA_API_Spec.yaml 8081
```

Copy the generated bundle to the web root:
```bash
sudo mkdir -p /var/www/api-docs
sudo cp -r ./api-docs-deploy/* /var/www/api-docs/
sudo chown -R www-data:www-data /var/www/api-docs
sudo chmod -R 755 /var/www/api-docs
```

### 4. Configure DNS
Add A records for your domain:
```
api.akura.in         → YOUR_SERVER_IP
api-staging.akura.in → YOUR_SERVER_IP (optional)
```

Verify DNS propagation:
```bash
nslookup api.akura.in
ping api.akura.in
```

### 5. Deploy Nginx Configuration
Copy the Nginx config:
```bash
sudo cp nginx-api.conf /etc/nginx/sites-available/api.akura.in
sudo ln -s /etc/nginx/sites-available/api.akura.in /etc/nginx/sites-enabled/
```

Test Nginx config:
```bash
sudo nginx -t
```

If successful, reload Nginx:
```bash
sudo systemctl reload nginx
```

### 6. Obtain SSL Certificate
Run Certbot for production:
```bash
sudo certbot --nginx -d api.akura.in
```

For staging (optional):
```bash
sudo certbot --nginx -d api-staging.akura.in
```

Follow prompts and select "Redirect HTTP to HTTPS" when asked.

### 7. Verify Setup
Test the endpoints:
```bash
# Health check
curl https://api.akura.in/healthz

# API docs
curl -I https://api.akura.in/docs

# Backend proxy
curl -I https://api.akura.in/api/health
```

## URL Structure

| Endpoint | Purpose | Backend |
|----------|---------|---------|
| `https://api.akura.in/docs` | Swagger UI API documentation | Static files from `/var/www/api-docs` |
| `https://api.akura.in/api/*` | Backend API proxy | `https://safestride-backend-cave.onrender.com` |
| `https://api.akura.in/healthz` | Nginx health check | Direct Nginx response |

## Updating API Documentation

When you update `AKURA_API_Spec.yaml`:

1. Re-run the deployment script:
```bash
cd /path/to/safestride/api-docs
bash ./deploy_api_docs.sh staging ./AKURA_API_Spec.yaml 8081
```

2. Copy updated files:
```bash
sudo cp -r ./api-docs-deploy/* /var/www/api-docs/
sudo systemctl reload nginx
```

## Troubleshooting

### DNS not resolving
```bash
# Check DNS
nslookup api.akura.in

# Flush local DNS cache (Windows)
ipconfig /flushdns

# Wait 15-60 minutes for propagation
```

### SSL certificate errors
```bash
# Check certificate status
sudo certbot certificates

# Renew manually if needed
sudo certbot renew --dry-run
sudo certbot renew

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Backend proxy not working
```bash
# Test backend directly
curl -I https://safestride-backend-cave.onrender.com/api/health

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Verify proxy_pass URL in nginx-api.conf
```

### CORS errors
- Ensure frontend origin matches in `add_header Access-Control-Allow-Origin`
- Check if backend is also setting CORS headers (potential conflict)
- Use browser DevTools Network tab to inspect preflight OPTIONS requests

### Docs not loading
```bash
# Check file permissions
ls -la /var/www/api-docs/

# Fix if needed
sudo chown -R www-data:www-data /var/www/api-docs
sudo chmod -R 755 /var/www/api-docs

# Verify index.html exists
ls -la /var/www/api-docs/index.html
```

## Security Best Practices

1. **Firewall**: Only allow ports 80, 443, and SSH
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

2. **Auto-renewal**: Certbot sets up auto-renewal; verify:
```bash
sudo systemctl status certbot.timer
```

3. **Rate limiting**: Add to Nginx config if needed:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=60r/m;

location /api {
    limit_req zone=api_limit burst=20 nodelay;
    # ... rest of config
}
```

4. **Fail2ban**: Protect against brute force:
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

## Maintenance

### Nginx commands
```bash
# Test config
sudo nginx -t

# Reload (graceful, no downtime)
sudo systemctl reload nginx

# Restart (brief downtime)
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### SSL renewal
Certbot auto-renews. To test:
```bash
sudo certbot renew --dry-run
```

Force renewal:
```bash
sudo certbot renew --force-renewal
```

## Alternative: Using Render Custom Domain

If you prefer not to self-host Nginx:

1. Deploy API docs as a separate Render Static Site
2. Use Render's custom domain feature:
   - API: `api.akura.in` → Backend service
   - Docs: `docs.api.akura.in` → Static site

This avoids server management but requires separate DNS records.

## Support

For issues, check:
- Nginx error logs: `/var/log/nginx/error.log`
- Certbot logs: `/var/log/letsencrypt/letsencrypt.log`
- Backend health: `https://safestride-backend-cave.onrender.com/api/health`
