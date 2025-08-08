# Cluster ArgoCD

### Root app - [`argocd-apps-root-app`](./argocd-apps-root-app/)

This app contains application definitions for other apps in this repository and crate a namespace for them.

```bash
kubectl apply -f argocd-apps-root-app/argocd-apps-root-app.yaml
```

### Sealed secrets

To convert an existing secret to a sealed secret, you can use the following command:

```bash
kubeseal -f secret.yaml -w sealedsecret.yaml --controller-namespace sealed-secrets --controller-name sealed-secrets --scope cluster-wide
```

### Applications

- [`authentik`](./apps/authentik/) - Open source identity provider ([goauthentik/authentik](https://github.com/goauthentik/authentik))
- [`backrest`](./apps/backrest/) - WebUI for backup tool restic ([garethgeorge/backrest](https://github.com/garethgeorge/backrest))
- [`bots`](./apps/bots/) - Discord bots
  - [`janr`](./apps/bots/janr/) - Funny bot ([Nasus20202/JanR](https://github.com/Nasus20202/JanR/))
  - [`leaguebot`](./apps/bots/leaguebot/) - League of Legends bot ([Nasus20202/lolbot](https://github.com/Nasus20202/lolbot))
  - [`logenz`](./apps/bots/logenz/) - Welcoming bot ([Nasus20202/Logenz](https://github.com/Nasus20202/Logenz))
  - [`ralphkaminski`](./apps/bots/ralphkaminski/) - Bot singing every hour ([Nasus20202/RalphKaminski](https://github.com/Nasus20202/RalphKaminski))
  - [`vodka`](./apps/bots/vodka/) - Lecture list bot ([Nasus20202/Vodka](https://github.com/nasus20202/Vodka))
- [`change-detection`](./apps/change-detection/) - Automated website change detector ([dgtlmoon/changedetection.io](https://github.com/dgtlmoon/changedetection.io))
- [`cloudnative-pg`](./apps/cloudnative-pg/) - PostgreSQL operator ([cloudnative-pg/cloudnative-pg](https://github.com/cloudnative-pg/cloudnative-pg))
- [`convertx`](./apps/convertx/) - Online file converter ([C4illin/ConvertX](https://github.com/C4illin/ConvertX))
- [`immich`](./apps/immich/) - Self hosted photo and video management ([immich-app/immich](https://github.com/immich-app/immich))
- [`nextcloud`](./apps/nextcloud/) - Self hosted cloud storage ([nextcloud/helm](https://github.com/nextcloud/helm))
- [`paczka`](./apps/paczka/) - Helpful resources hosted with FileBrowser Quantum ([gtsteffaniak/filebrowser](https://github.com/gtsteffaniak/filebrowser))
- [`paperless-ngx`](./apps/paperless-ngx/) - Document management system ([paperless-ngx/paperless-ngx](https://github.com/paperless-ngx/paperless-ngx/))
- [`portfolio-website`](./apps/portfolio-website/) - My personal website ([Nasus20202/portfolio-website](https://github.com/nasus20202/portfolio-website))
- [`rybbit`](./apps/rybbit/) - Self hosted analytics platform ([rybbit-io/rybbit](https://github.com/rybbit-io/rybbit))
- [`sealed-secrets`](./apps/sealed-secrets/) - Kubernetes controller to manage sealed secrets ([bitnami/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets))
- [`shlink`](./apps/shlink/) - URL shortener ([shlinkio/shlink](https://github.com/shlinkio/shlink))
- [`stirling-pdf`](./apps/stirling-pdf/) - online PDF tool ([Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF))
- [`uptime-kuma`](./apps/uptime-kuma/) - Uptime monitor ([louislam/uptime-kuma](https://github.com/louislam/uptime-kuma))
- [`vaultwarden`](./apps/vaultwarden/) - Self hosted password manager ([dani-garcia/vaultwarden](https://github.com/dani-garcia/vaultwarden))
