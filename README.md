# nginx-self-signed-tls

Local CA + TLS certs for dev domains, with an NGINX example.

One script. Creates a CA once, then issues a cert with the right SANs for any domain you give it. Trust the CA once and every cert it signs is green in the browser.

## Runbook

```bash
git clone https://github.com/coffeestained/nginx-self-signed-tls && cd nginx-self-signed-tls
./gen-certs.sh app.local                 # -> certs/ca.pem, certs/app.local.{crt,key}
echo "127.0.0.1 app.local" | sudo tee -a /etc/hosts

# trust the CA (once)
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.pem   # macOS
sudo cp certs/ca.pem /usr/local/share/ca-certificates/dev-ca.crt && sudo update-ca-certificates     # Debian/Ubuntu
certutil -addstore -f ROOT certs\ca.pem                                                               # Windows (admin)

# nginx
sudo mkdir -p /etc/nginx/certs && sudo cp certs/app.local.* /etc/nginx/certs/
sudo cp nginx.example.conf /etc/nginx/conf.d/app.local.conf && sudo nginx -t && sudo nginx -s reload
curl https://app.local
```

## Files

| file | purpose |
|---|---|
| `gen-certs.sh` | `gen-certs.sh <domain> [-o dir] [-d days] [-n ca_name]` |
| `nginx.example.conf` | TLS termination + reverse proxy to `:3333` |

Certs land in `certs/` (git-ignored). Firefox uses its own store: Settings → Certificates → Import `ca.pem`.

MIT © Matthew Grady
