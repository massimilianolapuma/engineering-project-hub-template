# Engineering Project Hub — your deployment

> 🇮🇹 [Versione italiana](README.it.md)

Template to run your own [Engineering Project Hub](https://github.com/massimilianolapuma/engineering-project-hub)
on **your** projects: a project-level view of multi-repository delivery, security, versions,
supply chain and a DORA / ISO 27001 related control map, built from GitHub (and optional
SonarQube, Harbor, Argo CD, Azure DevOps) and served as a static site behind a login.

- **Live demo (synthetic data):** https://massimilianolapuma.github.io/engineering-project-hub/
- **No backend.** Everything runs in **your** GitHub Actions, at a pinned hub release: a
  read-only GitHub App collects, a job without secrets builds, a third job publishes to
  Cloudflare Pages behind Cloudflare Access. Your data never leaves your accounts.
- **Free tiers are enough:** Cloudflare Pages + Access (up to 50 users), GitHub Actions.

## What this repository contains

| Path                                         | What                                                                     |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| `config/catalog.yaml`                        | Discovery: which GitHub owners to scan for project proposals              |
| `config/projects/*.yaml`                     | Your projects (one file each); the site's catalog editor proposes PRs here |
| `config/policies.yaml`                       | Health policies, thresholds, `publication.audience: restricted`          |
| `.github/workflows/deploy-hub.yml`           | Collect → build → deploy, calling the hub at a pinned release           |
| `.github/workflows/validate-config.yml`      | Validates `config/` on every pull request (no secrets)                   |
| `.github/workflows/cloudflare-bootstrap.yml` | One-off: checks the Cloudflare token and creates the Pages project       |
| `scripts/upgrade-hub.sh`                     | Pins a new hub release                                                   |

## Setup (about one hour)

### 1. Create your repository

**Use this template → Create a new repository**, and make it **Private**: the run logs, job
summaries and artifacts contain your real project names and findings.

### 2. Cloudflare

1. Add your domain to Cloudflare (full DNS: Access protects only proxied hostnames) and choose
   a hostname for the portal, e.g. `hub.<your-domain>`.
2. Create an **API token** (My Profile → API Tokens → Custom token): **Account → Cloudflare
   Pages → Edit**, your account only, with an expiry date. Note the **Account ID**.
3. In this repository: Settings → Environments → **New environment** `production`, deployment
   branches **main only** (the deploy and bootstrap jobs run in it).
4. Settings → Secrets and variables → Actions: secret `CLOUDFLARE_API_TOKEN`; variables
   `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_PAGES_PROJECT` (e.g. `engineering-project-hub`),
   `HUB_SITE_URL` (`https://hub.<your-domain>`).
5. Actions → **Cloudflare bootstrap (manual)** → Run workflow: it creates the Pages project.
6. Cloudflare → Workers & Pages → your project → **Custom domains** → add `hub.<your-domain>`.

### 3. Cloudflare Access (login)

Follow the hub guide [Protected hosting → Cloudflare Access](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/protected-hosting.md#2-cloudflare-access-with-github-login):
a self-hosted application covering **all** of `hub.<your-domain>`,
`<project>.pages.dev` and `*.<project>.pages.dev`, with a policy limited to your GitHub
organisation (or your company identity provider).

> ⚠️ If a `pages.dev` hostname is missing from the Access application, the site is reachable
> without login.

### 4. GitHub App (read-only collector)

Create a GitHub App in your organisation (Settings → Developer settings → GitHub Apps → New),
webhook **off**, "Only on this account", with **read-only** repository permissions:

| Permission             | Used for                                                    |
| ---------------------- | ----------------------------------------------------------- |
| Metadata               | repositories, branch rules (always on)                      |
| Contents               | manifests, workflow files, releases, tags                   |
| Actions                | workflow runs, CI summaries, the hub's own history artifact |
| Code scanning alerts   | code scanning alerts and analyses                           |
| Dependabot alerts      | dependency alerts                                           |
| Secret scanning alerts | secret alert counts (never the secret)                      |
| Deployments            | the deployments ledger (control map delivery checks)        |

Optional: organisation **Members: read** (team discovery), **Code quality: read**. Install the
App **only on the repositories to monitor**, then generate a private key.

Repository secrets: `GH_APP_ID`, `GH_APP_PRIVATE_KEY` (the PEM content),
`GH_APP_INSTALLATION_ID` (from the installation URL). Delete the downloaded key file afterwards.

### 5. Your catalog

- `config/catalog.yaml`: replace `your-org` with your organisation.
- `config/projects/`: replace `example-service.yaml` with your projects, or delete it and add
  projects later from the site's **Catalog** page (it proposes pull requests to this
  repository, validated by `validate-config.yml`).
- `config/policies.yaml`: the defaults are a sensible start;
  [configuration reference](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/configuration.md).

### 6. First run

Actions → **Deploy — Engineering Project Hub (protected)** → Run workflow. Then open
`https://hub.<your-domain>`: you should be asked to log in first.

```bash
# Without a login, every hostname must redirect to Cloudflare Access (302).
curl -sI https://hub.<your-domain>/ | grep -iE '^(HTTP|location)'
curl -sI https://<project>.pages.dev/data/index.json | grep -iE '^(HTTP|location)'
```

### 7. Schedule

In `.github/workflows/deploy-hub.yml` uncomment `schedule` and `push`: the hub then refreshes
every 6 hours and after every catalog change.

## Upgrading

```bash
./scripts/upgrade-hub.sh v0.18.0   # pins the release commit in the workflows
git diff                           # read the hub CHANGELOG, then commit and push
```

The repository never follows the hub's `main`: only released, tagged code runs next to your
credentials.

## Optional features

- **Teams notifications** of worsening projects: [notifications](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/notifications.md).
- **Deployments ledger** for environments deployed outside GitHub (Azure DevOps…):
  [deployments ledger](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/deployments-ledger.md).
- **Control map** (DORA / ISO 27001 related technical checks; not a compliance assessment):
  [control map](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/control-map.md).
- **SonarQube, Harbor, Argo CD**: [external providers](https://github.com/massimilianolapuma/engineering-project-hub/blob/main/docs/configuration.md#external-providers-configprovidersyaml).

## Security notes

- Everyone allowed by the Access policy sees every project in the catalog: keep the policy as
  narrow as your most sensitive project requires.
- Keep GitHub App keys and the Cloudflare token in secrets only; rotate them; never commit them.
- Settings → Actions → General: default `GITHUB_TOKEN` permissions **read-only**.

Licence: MIT. Questions and ideas:
[issues of the hub](https://github.com/massimilianolapuma/engineering-project-hub/issues).
