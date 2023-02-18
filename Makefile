.PHONY=daemon
daemon:
	# nix build .#img-nix-daemon && docker load < result
	docker compose -p daemon -f docker-compose.daemon.yml down -v
	docker compose -p daemon -f docker-compose.daemon.yml up -d

.PHONY=portainer
portainer:
	docker compose -p portainer -f docker-compose.portainer.yml up -d

.PHONY=test-daemon
test-daemon:
	# Check nix store content for hello world
	docker exec builder nix build .#hello
	docker exec builder ls -al /nix/store
