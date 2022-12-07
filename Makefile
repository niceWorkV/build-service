export PATH:=${PATH}:/$(shell pwd)/bins/repo-manager
export GPG_TTY=$(tty)

install_dep:
	sudo dnf -y install jq perl perl-CPAN expect rpm-sign
	export PERL_MM_USE_DEFAULT=1
	sudo dnf -y config-manager \
			--add-repo \
			https://download.docker.com/linux/fedora/docker-ce.repo
	sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
	cpan install JSON::Parse
	cpan install Template::Toolkit
	cpan install Config::IniFiles

setup: create_volumes
	./setup.pl

start_services:
	docker compose up	--build

add_volumes:
	docker volume create builder-config
	docker volume create build_results
	docker volume create rpm_sources
remove_volumes:
	docker-compose down --volumes
	docker volume rm builder-config
	docker volume rm build_results
	docker volume rm rpm_sources
add_confs:
	sudo cp ./etc/general/oracle.repo $(shell docker inspect builder-config | jq .[].Mountpoint)

show_sources:
	sudo ls -al $(shell docker inspect rpm_sources | jq .[].Mountpoint)
show_result:
	sudo ls -al $(shell docker inspect build_results | jq .[].Mountpoint)

sync_build_result:
	sudo rsync -aHv --delete "$(shell docker inspect build_results | jq .[].Mountpoint)/" "./builds/RPMs/"
	sudo chown -R ${USER}:${USER} "./builds/RPMs/"

sign:
	sign_all.sh --pass="d2d2"

create_volumes: add_volumes add_confs
recreate_volumes: remove_volumes create_volumes
restart_services: recreate_volumes setup start_services
build: restart_services sync_build_result
create_repo: build sync_build_result sign
	sudo createrepo "./builds/RPMs/"
deploy: install_dep setup
