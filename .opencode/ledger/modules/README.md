# Ledger por modulo

Cada modulo da cadeia de protecao pode ter seu proprio ledger dentro desta pasta
(`modules/<modulo>.md`), usado pelo `hacker-trust-ledger-update` para registrar eventos
especificos de cada modulo quando alterado.

Modulos (quando tocados, criar o ledger correspondente):
- `modules/wireguard-host.md` (WireGuard local, VPN oficial do pesquisador)
- `modules/proton-host.md` (Proton VPN app no host, camada adicional)
- `modules/gluetun.md` (VPN secundaria do sandbox)
- `modules/torproxy.md` (torproxy-host + torproxy-vpn)
- `modules/kali-sandbox.md` (container Kali)
- `modules/kill-switch.md` (iptables OUTPUT DROP)
- `modules/scripts.md` (verificar-vazamento, iniciar-sessao, encerrar-sessao, validar-dns-fix, session-start-hacking-security)
- `modules/docker-compose.yml` (composicao dos containers)
- `modules/dns-fix.md` (NetworkManager + systemd-resolved + fix)

Nao criar todos os ledgers de uma vez. Criar apenas quando o modulo for alterado (append-only).