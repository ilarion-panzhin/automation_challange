# Demo: TLS termination (self-signed)

Goal:
- Show HTTPS works via ingress (TLS termination at ingress-nginx).
- Self-signed is acceptable for the challenge.

Open:
- https://20.126.210.29/

Expected:
- Browser warning about self-signed certificate (ok for demo).
- After accepting, page loads.

Key points:

- TLS terminates on ingress-nginx.
- In production: real domain + cert-manager (ACME) or Key Vault certs.

Additional evidence:
```bash
kubectl -n hello get secret
kubectl -n hello describe ingress hello
```