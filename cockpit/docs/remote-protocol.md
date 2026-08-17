# Protocolo Cockpit Remote (v1, rascunho da Wave 0)

Protocolo cliente ↔ `cockpit-server` do plano 58. Nesta wave cobre o
**handshake** e o **domínio Terminais**; arquivos, git e databases entram nas
waves seguintes com o mesmo envelope.

As mensagens são classes Dart em `packages/cockpit_protocol` — a mesma classe
serializa e desserializa nos dois lados do fio. Este documento descreve o
formato no fio para debugging e para futuros clientes.

## Transporte

- **Framing**: JSONL — um objeto JSON por linha (`\n`), UTF-8. O despacho é
  por linha, nunca por `onDone` (lição do socket da CLI interna: esperar
  `onDone` deadlocka request/response).
- **Canal**: socket local (UDS no POSIX). Remoto = o MESMO socket tunelado
  por SSH (Wave 2); o protocolo não muda. O servidor nunca escuta em porta
  de rede.
- **Bytes de PTY**: base64 no campo `d`. (Candidato a otimização em wave
  futura: frame binário; só se o benchmark pedir.)
- **Autenticação**: nenhuma no canal — quem alcança o socket é dono
  (permissão de filesystem no UDS; login SSH no túnel). Decisões G/H do
  plano 58.

## Envelope

```json
{"t": "<tipo>", ...campos}
```

Campos comuns: `id` = id de sessão PTY; `d` = payload base64; `off` = offset
absoluto em bytes do stream da sessão desde o spawn.

## Handshake

O cliente abre a conexão e envia `hello`; o servidor responde `hello.ack` ou
`err{code: version_mismatch}` e fecha. Toda mensagem antes do `hello` é
rejeitada com `err{code: handshake_required}`.

| Direção | Mensagem | Campos |
|---|---|---|
| C→S | `hello` | `v` (int, versão do protocolo), `client` (nome/versão) |
| S→C | `hello.ack` | `v`, `server` (versão do binário) |

`v` é comparado por igualdade nesta fase. Incompatível → o cliente oferece
"Update server" (bootstrap pelo túnel, Wave 2).

## Domínio Terminais

Modelo: **sessões pertencem ao servidor**, não à conexão. Detach (ou queda da
conexão) não mata a sessão; reattach recupera o scrollback retido (ring
buffer de bytes crus, default 4 MiB por sessão) e continua live. O emulador
(Ghostty) vive no cliente; o servidor não interpreta os bytes.

| Direção | Mensagem | Campos | Resposta |
|---|---|---|---|
| C→S | `pty.open` | `cmd`, `args[]`, `cwd?`, `env{}?`, `rows`, `cols` | `pty.opened{id, pid}` ou `err` |
| C→S | `pty.list` | — | `pty.sessions{sessions[]}` (`{id,pid,cmd,rows,cols,len,exit?}`) |
| C→S | `pty.attach` | `id`, `from` (offset; 0 = replay do retido) | stream de `pty.output` + `pty.exited` |
| C→S | `pty.detach` | `id` | (nada; sessão segue viva) |
| C→S | `pty.input` | `id`, `d` | — |
| C→S | `pty.resize` | `id`, `rows`, `cols` | — |
| C→S | `pty.kill` | `id` | — (mata processo E descarta a sessão) |
| S→C | `pty.output` | `id`, `off`, `d` | — |
| S→C | `pty.exited` | `id`, `code` | — (scrollback segue anexável até `pty.kill`) |

Semântica do offset: `off` é a posição absoluta do primeiro byte do chunk no
stream total da sessão. No attach com `from` anterior ao retido, o primeiro
chunk chega com `off` maior que o pedido — o cliente sabe que perdeu o início.
O replay nunca duplica nem perde bytes em relação ao live (o servidor filtra
por offset na costura replay→live).

## Erros

```json
{"t": "err", "code": "<código estável>", "detail": "<texto cru>", "id": "<sessão>?"}
```

Códigos atuais: `handshake_required`, `version_mismatch`, `bad_message`,
`session_not_found`, `spawn_failed`, `internal`. `code` é contrato (a UI
traduz por enum); `detail` é texto de terceiros (errno etc.), exibido cru.

## Aberto (para as próximas waves)

- Backpressure/coalescing de output no fio (integrar com o
  `pty_output_scheduler` de `docs/terminal-output-flow-control.md`).
- Resize com N clientes attached (política tmux a decidir).
- Frame binário para `pty.output` se o benchmark apontar o base64.
- Envelopes dos domínios Arquivos, Git e Databases.
