# Engineering Project Hub — la tua installazione

> 🇬🇧 [English version](README.md)

Template per far girare il tuo [Engineering Project Hub](https://github.com/massimilianolapuma/engineering-project-hub)
sui **tuoi** progetti: una vista per progetto di delivery multi-repository, sicurezza, versioni,
catena di fornitura e una mappa dei controlli collegata a DORA / ISO 27001, costruita da GitHub
(e, se vuoi, SonarQube, Harbor, Argo CD, Azure DevOps) e pubblicata come sito statico dietro un
login.

- **Demo (dati sintetici):** https://massimilianolapuma.github.io/engineering-project-hub/
- **Nessun backend.** Tutto gira nelle **tue** GitHub Actions, su una release dell'hub fissata: una
  GitHub App in sola lettura raccoglie i dati, un job senza segreti costruisce il sito, un terzo job
  lo pubblica su Cloudflare Pages dietro Cloudflare Access. I tuoi dati non escono dai tuoi account.
- **Bastano i piani gratuiti:** Cloudflare Pages + Access (fino a 50 utenti), GitHub Actions.

## Cosa contiene questa repository

| Percorso                                     | Cosa                                                                          |
| -------------------------------------------- | ----------------------------------------------------------------------------- |
| `config/catalog.yaml`                        | Discovery: quali owner GitHub scansionare per proporre progetti                |
| `config/projects/*.yaml`                     | I tuoi progetti (un file ciascuno); l'editor del catalogo del sito propone PR qui |
| `config/policies.yaml`                       | Policy di salute, soglie, `publication.audience: restricted`                   |
| `.github/workflows/deploy-hub.yml`           | Raccolta → build → pubblicazione, chiamando l'hub su una release fissata       |
| `.github/workflows/validate-config.yml`      | Valida `config/` a ogni pull request (senza segreti)                           |
| `.github/workflows/cloudflare-bootstrap.yml` | Una tantum: verifica il token Cloudflare e crea il progetto Pages              |
| `scripts/upgrade-hub.sh`                     | Fissa una nuova release dell'hub                                               |

## Configurazione (circa un'ora)

### 1. Crea la tua repository

**Use this template → Create a new repository**, e rendila **Private**: log, riepiloghi e
artifact delle esecuzioni contengono i nomi reali dei progetti e gli alert.

### 2. Cloudflare

1. Aggiungi il tuo dominio a Cloudflare (DNS completo: Access protegge solo gli hostname gestiti
   da Cloudflare) e scegli un hostname per il portale, es. `hub.<tuo-dominio>`.
2. Crea un **API token** (My Profile → API Tokens → Custom token): **Account → Cloudflare Pages →
   Edit**, solo sul tuo account, con una scadenza. Annota l'**Account ID**.
3. In questa repository: Settings → Environments → **New environment** `production`, branch di
   deploy **solo main** (i job di deploy e di bootstrap girano lì).
4. Settings → Secrets and variables → Actions: segreto `CLOUDFLARE_API_TOKEN`; variabili
   `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_PAGES_PROJECT` (es. `engineering-project-hub`),
   `HUB_SITE_URL` (`https://hub.<tuo-dominio>`).
5. Actions → **Cloudflare bootstrap (manual)** → Run workflow: crea il progetto Pages.
6. Cloudflare → Workers & Pages → il tuo progetto → **Custom domains** → aggiungi
   `hub.<tuo-dominio>`.

### 3. Cloudflare Access (login)

Segui la guida dell'hub [Pubblicazione protetta → Cloudflare Access](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/protected-hosting.md):
un'applicazione self-hosted che copre **tutti** gli hostname `hub.<tuo-dominio>`,
`<progetto>.pages.dev` e `*.<progetto>.pages.dev`, con una policy limitata alla tua
organizzazione GitHub (o all'identity provider aziendale).

> ⚠️ Se manca un hostname `pages.dev` nell'applicazione Access, il sito è raggiungibile senza
> login.

### 4. GitHub App (raccolta in sola lettura)

> **Con un clic:** apri la [pagina di configurazione della GitHub App](https://massimilianolapuma.github.io/engineering-project-hub/it/setup/github-app/), inserisci la
> tua organizzazione e questa repository, conferma su GitHub, poi esegui i comandi `gh` che la
> pagina mostra: salvano qui `GH_APP_ID` e `GH_APP_PRIVATE_KEY`. La chiave privata va da GitHub
> solo al tuo terminale. Poi installa l'App (sotto) e aggiungi `GH_APP_INSTALLATION_ID`. Per
> farlo a mano:

Crea una GitHub App nella tua organizzazione (Settings → Developer settings → GitHub Apps → New),
webhook **spento**, "Only on this account", con permessi di repository **in sola lettura**:

| Permesso               | Serve per                                                       |
| ---------------------- | --------------------------------------------------------------- |
| Metadata               | repository, regole dei branch (sempre attivo)                   |
| Contents               | manifest, file dei workflow, release, tag                       |
| Actions                | esecuzioni dei workflow, riepiloghi della CI, storico dell'hub   |
| Code scanning alerts   | alert e analisi di code scanning                                |
| Dependabot alerts      | alert sulle dipendenze                                          |
| Secret scanning alerts | conteggi degli alert sui segreti (mai il segreto)               |
| Deployments            | il registro dei deploy (controlli di rilascio della mappa)      |

Facoltativi: **Members: read** a livello di organizzazione (discovery dei team), **Code quality:
read**. Installa l'App **solo sulle repository da monitorare**, poi genera una chiave privata.

Segreti di repository: `GH_APP_ID`, `GH_APP_PRIVATE_KEY` (il contenuto PEM),
`GH_APP_INSTALLATION_ID` (dall'URL dell'installazione). Poi cancella il file della chiave
scaricato.

### 5. Il tuo catalogo

- `config/catalog.yaml`: sostituisci `your-org` con la tua organizzazione.
- `config/projects/`: sostituisci `example-service.yaml` con i tuoi progetti, oppure cancellalo e
  aggiungi i progetti dopo dalla pagina **Catalogo** del sito (propone pull request in questa
  repository, validate da `validate-config.yml`).
- `config/policies.yaml`: i valori di default sono un buon inizio;
  [riferimento della configurazione](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/configuration.md).

### 6. Prima esecuzione

Actions → **Deploy — Engineering Project Hub (protected)** → Run workflow. Poi apri
`https://hub.<tuo-dominio>`: deve chiederti prima il login.

```bash
# Senza login, ogni hostname deve reindirizzare a Cloudflare Access (302).
curl -sI https://hub.<tuo-dominio>/ | grep -iE '^(HTTP|location)'
curl -sI https://<progetto>.pages.dev/data/index.json | grep -iE '^(HTTP|location)'
```

### 7. Esecuzione programmata

In `.github/workflows/deploy-hub.yml` togli il commento a `schedule` e `push`: l'hub si aggiorna
ogni 6 ore e dopo ogni modifica al catalogo.

## Aggiornamenti

```bash
./scripts/upgrade-hub.sh v0.18.0   # fissa il commit della release nei workflow
git diff                           # leggi il CHANGELOG dell'hub, poi commit e push
```

La repository non segue mai il `main` dell'hub: accanto alle tue credenziali gira solo codice
rilasciato e taggato.

## Funzioni facoltative

- **Notifiche su Teams** dei progetti che peggiorano: [notifiche](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/notifications.md).
- **Registro dei deploy** per gli ambienti rilasciati fuori da GitHub (Azure DevOps…):
  [registro dei deploy](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/deployments-ledger.md).
- **Mappa dei controlli** (controlli tecnici collegati a DORA / ISO 27001; non è una valutazione
  di adeguatezza normativa): [mappa dei controlli](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/control-map.md).
- **SonarQube, Harbor, Argo CD**: [provider esterni](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/it/configuration.md).

## Note di sicurezza

- Chiunque passi la policy di Access vede tutti i progetti del catalogo: tieni la policy stretta
  quanto richiede il progetto più sensibile.
- Tieni le chiavi della GitHub App e il token Cloudflare solo nei segreti; ruotali; non
  committarli mai.
- Settings → Actions → General: permessi di default del `GITHUB_TOKEN` **in sola lettura**.

Licenza: MIT. Domande e idee:
[issue dell'hub](https://github.com/massimilianolapuma/engineering-project-hub/issues).
