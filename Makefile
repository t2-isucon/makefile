SHELL=/bin/bash

SERVICE_NAME=isuports
WEBAPP_NAME=isuports

WORK_DIR=./isucon12-qualify
WEBAPP_GO_PATH=$(WORK_DIR)/webapp/go
WEBAPP_PATH=$(WEBAPP_GO_PATH)/$(SERVICE_NAME)


GO_TARGET_PATH=/home/isucon/webapp/go/$(SERVICE_NAME)

GOBIN=/home/isucon/local/go/bin/go

BRANCH:=main

pull:
	cd $(WORK_DIR) && \
	git fetch --all &&\
	git switch $(BRANCH) &&\
	git reset --hard origin/$(BRANCH)

update_config: pull
	sudo cp "$(WORK_DIR)/etc/alternatives/my.cnf" /etc/alternatives/my.cnf
	sudo cp -r "$(WORK_DIR)/etc/mysql/mysql.conf.d" /etc/mysql/mysql.conf.d
	sudo cp "$(WORK_DIR)/etc/nginx/nginx.conf" /etc/nginx/nginx.conf
	sudo cp -r "$(WORK_DIR)/etc/nginx/sites-available" /etc/nginx/sites-available
	sudo cp "$(WORK_DIR)/etc/systemd/system/isuports.service" /etc/systemd/system/isuports.service
	sudo cp -r "${WORK_DIR}/webapp" /home/isucon/webapp/
	sudo systemctl daemon-reload

mysql.restart: update_config
	sudo systemctl restart mysql
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

#go.build: pull go.stop
#	cd $(WEBAPP_GO_PATH) && \
#	$(GOBIN) build -o $(GO_TARGET_PATH)

go.restart: update_config go.enable
	sudo systemctl restart $(WEBAPP_NAME)

go.disable: go.stop
	sudo systemctl disable $(WEBAPP_NAME)

go.enable:
	sudo systemctl enable ${WEBAPP_NAME}
	sudo systemctl start ${WEBAPP_NAME}

journalctl.vacuum:
	sudo journalctl --rotate
	sudo journalctl --vacuum-time=1s

