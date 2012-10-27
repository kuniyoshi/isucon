all: prepare git

preppare:
	mkdir -p ~root/service

git:
	cp -R git ~root/service

starman:
	if [ -z "$(grep logadmin /etc/passwd)" ]; then useradd -r -M -s /sbin/nologin logadmin; fi
	rsync -avn starman/ .starman
	chown logadmin:logadmin .starman/log
	mv .starman /service/starman
