# GitLab Runner on Kubernetes

This document provides instructions on how to deploy a GitLab Runner on Kubernetes using Helm.

## Prerequisites

- A Kubernetes cluster
- `helm` command-line tool installed

## Installation

1. **Add the GitLab Helm repository:**

```bash
helm repo add gitlab https://charts.gitlab.io
```

2. **Create a namespace for the GitLab Runner:**

```bash
kubectl create namespace gitlab-runner
```

3. **Create a `gitlab-runner-template.yml` file:**

Create a file named `gitlab-runner-template.yml` with the following content, replacing `YOUR_RUNNER_TOKEN` with the token provided by your GitLab instance:

```yaml
gitlabUrl: https://git.bbg.pe
runnerToken: "YOUR_RUNNER_TOKEN"
rbac:
   create: true
runners:
   privileged: true
   kubernetes:
      privileged: true
      allowPrivilegeEscalation: true
      securityContext:
      privileged: true
      allowPrivilegeEscalation: true
```

4. **Install the GitLab Runner:**

```bash
helm install --namespace gitlab-runner gitlab-runner -f gitlab-runner-template.yml gitlab/gitlab-runner
```

## Upgrade

To upgrade the GitLab Runner, run the following command:

```bash
helm upgrade --namespace gitlab-runner gitlab-runner -f gitlab-runner-template.yml gitlab/gitlab-runner
```

## Uninstallation

To uninstall the GitLab Runner, run the following command:

```bash
helm uninstall --namespace gitlab-runner gitlab-runner
```
