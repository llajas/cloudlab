.POSIX:
.PHONY: default compose infra platform apps test update

env ?= local

default: infra platform apps

compose:
	docker compose up --build --detach

infra: compose
	# TODO multiple env
	@temporal workflow start \
		--workflow-id infra-manual \
		--task-queue cloudlab \
		--type Infra \
		--input '{ "url": "https://github.com/llajas/cloudlab", "revision": "testing", "stack": "local" }'
	@temporal workflow result --workflow-id infra-manual

platform:
	# TODO multiple env
	@temporal workflow start \
		--workflow-id platform-manual \
		--task-queue cloudlab \
		--type Platform \
		--input '{ "url": "https://github.com/llajas/cloudlab", "revision": "testing", "registry": "registry.127.0.0.1.sslip.io", "cluster": "local" }'
	@temporal workflow result --workflow-id platform-manual

apps:
	# TODO multiple env
	@temporal workflow start \
		--workflow-id apps-manual \
		--task-queue cloudlab \
		--type Apps \
		--input '{ "url": "https://github.com/llajas/cloudlab", "revision": "testing", "registry": "registry.127.0.0.1.sslip.io", "cluster": "local" }'
	@temporal workflow result --workflow-id apps-manual

test:
	cd controller && go test ./...
	cd test && go test

fmt:
	nixfmt flake.nix
	yamlfmt \
		--exclude infra/modules/cluster/roles/secrets/vars/main.yml \
		--exclude infra/*/secrets.yaml \
		.
	terragrunt hcl format
	tofu fmt -recursive
	cd controller && go fmt ./...
	cd infra/modules/tfstate && go fmt ./...
	cd test && go fmt ./...

update:
	nix flake update

clean:
	docker compose down --remove-orphans --volumes
	k3d cluster delete local
