#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

SHELL = /bin/sh

WPCLI_CONTINER_NAME := wp-cli
WORDPRESS_CONTINER_NAME := wordpress

WPDATA_VOLUME_NAME := wordpress-data

IMAGES_PREFIX := $(shell basename $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

all_images = $(IMAGES_PREFIX):$(WORDPRESS_CONTINER_NAME)

docker_bin := $(shell command -v docker 2> /dev/null)
docker_compose_bin := $(shell command -v docker-compose 2> /dev/null)

.DEFAULT_GOAL := init

up: ## Start all containers (in background) for development
	$(docker_compose_bin) up --no-recreate -d
	sleep 10

down: ## Stop all started for development containers
	$(docker_compose_bin) down

core-install: ## Install wordpress core
	$(docker_compose_bin) run --rm "$(WPCLI_CONTINER_NAME)" wp core install --allow-root \
			--url=127.0.0.1:9997 \
			--title=development \
			--admin_user=root \
			--admin_password=root \
			--admin_email=root@root.com

clean: ## Remove images from local registry
	-$(docker_compose_bin) down -v
	$(foreach image,$(all_images),$(docker_bin) rmi -f $(image);)

plugins: ## Install wordpress plugins through wp-cli
	$(docker_compose_bin) run --rm "$(WPCLI_CONTINER_NAME)" wp plugin install --activate --allow-root \
		https://downloads.wordpress.org/plugin/debug-bar.1.0.zip \
		https://downloads.wordpress.org/plugin/query-monitor.3.3.7.zip \
		https://downloads.wordpress.org/plugin/log-deprecated-notices.0.4.1.zip \
		https://downloads.wordpress.org/plugin/monster-widget.zip \
		https://downloads.wordpress.org/plugin/developer.1.2.6.zip \
		https://downloads.wordpress.org/plugin/theme-check.20190801.1.zip

init: up core-install plugins ## Make full application initialization

clean: ## Remove images from local registry
	-$(docker_compose_bin) down -v
	$(foreach image,$(all_images),$(docker_bin) rmi -f $(image);)
