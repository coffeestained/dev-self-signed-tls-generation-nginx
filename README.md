# dev-self-signed-tls-generation-nginx
Self-Signed TLS Certificate Generation with NGINX Example Usage

## Generate CA Key (add an encryption flag such as -des3 if necessary)
`openssl genrsa -out certificate-authority.key 2048`

## Generate CA Certificate
```openssl req -x509 -new -nodes -sha256 -days 360 -key certificate-authority.key -out certificate-authority.pem```

## Generate TLS Key
```openssl genrsa -out tls.key 2048```

## Generate CSR from TLS Key
```openssl req -new -key tls.key -out tls.csr```

## Create signing.cfg file with the following contents:
```
  basicConstraints       = CA:FALSE
  authorityKeyIdentifier = keyid:always, issuer:always
  keyUsage               = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
  subjectAltName         = @alt_names
  
  [ alt_names ]
  DNS.1 = localDomain.local
  DNS.2 = *.localDomain.local
```
  
## Sign CSR using CA & Config
```openssl x509 -req \
 -in tls.csr \
-CA certificate-authority.pem -CAkey certificate-authority.key -CAcreateserial  \
-out tls.crt \
-days 360 -sha256 -extfile signing.cfg```

## Example NGINX Usage (Note that server_name matches signing.cfg alt_names
```
server {
    listen 443 ssl;

    server_name example.localDomain.local;

    ssl_certificate     \path\tls.crt;
    ssl_certificate_key \path\tls.key;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Depending on your machne, you may need to add/trist your new self-signed tls cert via:
1. keychain (mac)
2. mmc (windows) 
3. ```
mkdir /usr/local/share/ca-certificates/
cp <full_path_to_the_certificate> /usr/local/share/ca-certificates/
sudo update-ca-certificates
``` Linux
  
