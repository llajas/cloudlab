# Cloudlab

> [!IMPORTANT]
> This project is designed to manage my offsite setup, which is specific to my
> use cases, so it might not be directly useful to you. For a ready-to-use
> solution, please refer to my [homelab project](https://github.com/llajas/homelab).

## Project structure

```
.
├── flake.nix                             # Contains dependencies required by this project for both local and CI/CD
├── Makefile                              # Entry point for all manual actions
├── compose.yaml                          # Servers required for running locally
├── infra                                 # Infrastructure definition
│   ├── modules                           # Terraform modules
│   │   ├── network
│   │   ├── instance
│   │   ├── cluster
│   │   └── ...
│   ├── local                             # Terragrunt configuration for the local environment
│   │   └── ...
│   └── ${ENV}                            # Terragrunt configuration for the ${ENV} environment
│       ├── root.hcl                      # Root config used by other Terragrunt files
│       ├── secrets.yaml                  # Encrypted secrets
│       ├── tfstate                       # Bootstrap Terraform state
│       ├── ${CLOUD}
│       │   └── ${REGION}
│       │       └── ${MODULE}
│       │           └── terragrunt.hcl
│       ├── metal
│       │   └── vn-southeast-1
│       │       ├── bootstrap
│       │       │   └── terragrunt.hcl
│       │       └── cluster
│       │           └── terragrunt.hcl
│       └── ...
├── platform                              # Highly privileged platform components
│   └── ${ENV}
│       ├── grafana.yaml
│       ├── temporal.yaml
│       ├── wireguard.yaml
│       └── ...
├── apps                                  # User applications, standardized with strict controls
│   ├── ${NAMESPACE}
│   │   └── ${APP}
│   │       └── ${ENV}.yaml
│   └── llajas
│       └── blog
│           ├── local.yaml
│           └── production.yaml
├── controller                            # Automation controller for the entire project - think GitHub Actions, but better
│   ├── activities                        # Temporal activities (git clone, terragrunt apply, etc.)
│   │   ├── git.go
│   │   ├── terragrunt.go
│   │   └── ...
│   ├── workflows                         # Temporal workflows, define a sequence of activities
│   │   ├── infra.go
│   │   ├── app.go
│   │   └── ...
│   ├── worker                            # Worker process that executes the workflows
│   └── Dockerfile                        # Builds the image for the controller, can run locally or on a cluster
└── test                                  # High level tests
```

## Features

- Unified hybrid cloud platform
- Temporal is used as the automation engine, providing the reliability and
  performance that generic CI/CD engines can only dream of.
- Infra aka IaaS:
  - Essentially `cd "infra/${ENV}" && terragrunt apply --all`
  - Includes some graph pruning based on changed files for performance
  - Bootstrap ArgoCD to apply the remaining
- Platform aka PaaS:
  - Essentially `kubectl apply -f "platform/${ENV}"`
  - However, the runtime doesn’t have access to Git - all manifests are pulled from an OCI registry
- Apps aka SaaS:
  - Strict and standardized
  - Uses the rendered manifests pattern, essentially `helm template && oras push`

## Estimated cost

| Provider     | Service                                                     | Usage | Pricing     |
| :--          | :--                                                         | :--   | :--         |
| Metal        | Hardware depreciation                                       |       | 76.32$/year |
| Metal        | Electricity                                                 |       | 36$/year    |
| Oracle Cloud | Virtual Cloud Network                                       | 1     | Free        |
| Oracle Cloud | `VM.Standard.A1.Flex` (ARM) - 4 cores, 24GB RAM, 200GB disk | 1     | Free        |
| Hetzner      | VM `CAX21` - 4 cores, 8GB RAM, 80GB disk                    | 1     | 83.88$/year |
| Cloudflare   | R2 Bucket (Terraform state)                                 | 2     | Free        |
| Cloudflare   | Domain                                                      | 2     | 20$/year    |
| Cloudflare   | Load Balancer                                               | 1     | 60$/year    |
| Cloudflare   | Tunnel                                                      | 2     | Free        |
| Backblaze    | B2 Bucket (backup)                                          | 1TB   | 72$/year    |
| **Total**    |                                                             |       | 348.2$/year |

## Get started

### Prerequisites

- Fork this repository because you will need to customize it for your needs.
- A credit/debit card to register for the accounts.
- Basic knowledge on Terraform, Ansible and Kubernetes (optional, but will help a lot)

Configuration files:

<details>

<summary>Terraform Cloud</summary>

- Create a Terraform Cloud account at <https://app.terraform.io>

</details>

<details>

<summary>Oracle Cloud</summary>

- Create an Oracle Cloud account at <https://cloud.oracle.com>
- Generate an API signing key:
  - Profile menu (User menu icon) -> User Settings -> API Keys -> Add API Key
  - Select Generate API Key Pair, download the private key to `~/.oci/private.pem` and click Add
  - Copy the Configuration File Preview to `~/.oci/config` and change `key_file` to `~/.oci/private.pem`

If you see a warning like this, try to avoid those regions:

> ⚠️ Because of high demand for Arm Ampere A1 Compute capacity in the Foo and Bar regions, A1 instance availability in these regions is limited.
> If you plan to create A1 instances, we recommend choosing another region as your home region

</details>

Install the following packages:

- [Nix](https://nixos.org/download.html)

That's it! Run the following command to open the Nix shell:

```sh
nix develop
```

### Provision

Build the infrastructure:

```sh
make
```

## TODOs

- Fix OCI plain HTTP for local development
- Config git username and email
- Credentials for the worker (SSH priv + pub + knowhosts?)
- Contract between clouds:
  - Compute, x86_64 or aarch64
  - Public IPv6
  - Allow ports:
    - 443
    - 80 (for HTTP-01)
    - 22
    - 51820 and 51821 (for Wireguard IPv4 and IPv6)
  - NixOS, with SSH access
- Firewall rules (currently manually managed in routers):
  - TCP: 6443 (Kube API), 443 (HTTPS), 80 (HTTP), 10250 (Kubelet metrics), 22 (SSH)
  - UDP: 51820 (Wireguard IPv4), 51821 (Wireguard IPv6)

## Acknowledgments and References

- [Oracle Terraform Modules](https://github.com/oracle-terraform-modules)
- [Official k3s systemd service file](https://github.com/k3s-io/k3s/blob/master/k3s.service)
- [Sample Prometheus configuration for Istio](https://github.com/istio/istio/blob/master/samples/addons/extras/prometheus-operator.yaml)
- [Terraform and nixos-anywhere infrastructure for wiki.nixos.org](https://github.com/NixOS/nixos-wiki-infra)
