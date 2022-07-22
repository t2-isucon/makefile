SHELL=/bin/bash

SERVICE_NAME=isucondition
WEBAPP_NAME=isucondition.go

WORK_DIR=./isucon11-qualify-20220722
WEBAPP_GO_PATH=$(WORK_DIR)/webapp/go
WEBAPP_PATH=$(WEBAPP_GO_PATH)/$(SERVICE_NAME)


GO_TARGET_PATH=webapp/go/$(SERVICE_NAME)

BRANCH:=main

pull:
	cd $(WORK_DIR) && \
	git fetch --all &&\
	git switch $(BRANCH) &&\
	git reset --hard origin/$(BRANCH)

update_config: pull
	sudo cp "$(WORK_DIR)/env.sh" /home/isucon/env.sh
	sudo cp "$(WORK_DIR)/nginx/nginx.conf" /etc/nginx/nginx.conf || true 
	sudo cp "$(WORK_DIR)/nginx/sites-enabled/isucondition.conf" /etc/nginx/sites-enabled/isucondition.conf || true
	sudo cp "$(WORK_DIR)/mysql/my.cnf" /etc/mysql/conf.d/my.cnf || true

mysql.restart: update_config
	sudo systemctl restart mysqld
	sudo -u mysql bash -c 'test -f /var/log/mysql/mysql-slow.log && cp /var/log/mysql/mysql-slow.log /var/log/mysql/mysql-slow.log.$(shell date +%s) && echo > /var/log/mysql/mysql-slow.log' || true

# mysql.enable: 
# 	sudo systemctl enable mariadb.servicel
# 	sudo systemctl start mariadb.service
# 
# mysql.disable: 
# 	sudo systemctl stop mariadb.service
# 	sudo systemctl disable mariadb.service

nginx.restart: update_config
	sudo systemctl restart nginx

nginx.enable: 
	sudo systemctl enable nginx
	sudo systemctl start nginx

nginx.disable: 
	sudo systemctl stop nginx
	sudo systemctl disable nginx

go.stop:
	sudo systemctl stop $(WEBAPP_NAME)

go.build: pull go.stop
	cd $(WEBAPP_GO_PATH) && \
	go build -o $(GO_TARGET_PATH)

go.restart: update_config go.build
	sudo systemctl restart $(WEBAPP_NAME)

go.disable: go.stop
	sudo systemctl disable $(WEBAPP_NAME)
