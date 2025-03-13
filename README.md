# Cluster ArgoCD

### Root app - [`argocd-root-app`](./argocd-root-app/)

This app contains application definitions for other apps in this repository and crate a namespace for them.

```bash
kubectl apply -f argocd-root-app.yaml
```

### Seal secrets

To convert an existing secret to a sealed secret, you can use the following command:

```bash
kubeseal -f secret.yaml -w sealedsecret.yaml --controller-namespace sealed-secrets --controller-name sealed-secrets --scope cluster-wide
```

### Applications

- [`bots`](./apps/bots/) - Discord bots
  - [`janr`](./apps/bots/janr/) - funny bot ([Nasus20202/JanR](https://github.com/Nasus20202/JanR/))
  - [`leaguebot`](./apps/bots/leaguebot/) - League of Legends bot ([Nasus20202/lolbot](https://github.com/Nasus20202/lolbot))
  - [`logenz`](./apps/bots/logenz/) - welcoming bot ([Nasus20202/Logenz](https://github.com/Nasus20202/Logenz))
  - [`ralphkaminski`](./apps/bots/ralphkaminski/) - bot singing every hour ([Nasus20202/RalphKaminski](https://github.com/Nasus20202/RalphKaminski))
  - [`vodka`](./apps/bots/vodka/) - Lecture list bot ([Nasus20202/Vodka](https://github.com/nasus20202/Vodka))
- [`minecraft`](./apps/minecraft/) - Minecraft server ([itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server))
- [`nextcloud`](./apps/nextcloud/) - self hosted cloud storage ([nextcloud/helm](https://github.com/nextcloud/helm))
- [`paczka`](./apps/paczka/) - GUT helpful resources hosted with FileBrowser ([filebrowser/filebrowser](https://github.com/filebrowser/filebrowser))
- [`portfolio-website`](./apps/portfolio-website/) - my personal website ([Nasus20202/portfolio-website](https://github.com/nasus20202/portfolio-website))
- [`postgres`](./apps/postgres/) - PostgreSQL database ([bitnami/postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql))
- [`sealed-secrets`](./apps/sealed-secrets/) - Kubernetes controller to manage sealed secrets ([bitnami/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets))
- [`shlink`](./apps/shlink/) - URL shortener ([shlinkio/shlink](https://github.com/shlinkio/shlink))
- [`stirling-pdf`](./apps/stirling-pdf/) - online PDF tool ([Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF))
- [`uptime-kuma`](./apps/uptime-kuma/) - uptime monitor ([louislam/uptime-kuma](https://github.com/louislam/uptime-kuma))
