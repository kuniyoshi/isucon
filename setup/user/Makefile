USERADD=/usr/sbin/useradd
ISUCON_GROUP=isucon
HOSTS=192.168.1.122 192.168.1.123 192.168.1.124

all: root rsync_root prepare purasi-bo create_users rsync_users

root:
	(umask 077 && mkdir /root/.ssh)
	(umask 077 && cat /tmp/id_rsa >/root/.ssh/id_rsa)
	(umask 022 && cat /tmp/id_rsa.pub >/root/.ssh/id_rsa.pub)
	(umask 077 && cat /tmp/id_rsa.pub >/root/.ssh/authorized_keys)
	restorecon -R /root/.ssh

rsync_root:
	for x in $(HOSTS); do rsync -av /root/.ssh $$x:/root; done
	for x in $(HOSTS); do ssh $$x restorecon -R /root/.ssh; done

prepare:
	yum install -y zsh
	for x in $(HOSTS); do ssh $$x yum install -y zsh; done

purasi-bo:
	$(USERADD) -G wheel,$(ISUCON_GROUP) -s /bin/zsh purasi-bo
	git clone -b isucon git://github.com/kuniyoshi/dotfiles.git ~purasi-bo/dotfiles
	cd ~purasi-bo/dotfiles && sudo -H -u purasi-bo make install && cd -
	echo 'export GIT_AUTHOR_EMAIL=kuniyoshi@cpan.com\n''export GIT_COMMITTER_EMAIL=kuniyoshi@cpan.com\n''export EMAIL=kuniyoshi@cpan.com\n' >~purasi-bo/.secretrc
	(umask 077 && mkdir ~purasi-bo/.ssh)
	(umask 077 && cat /tmp/id_rsa >~purasi-bo/.ssh/id_rsa)
	(umask 022 && cat /tmp/id_rsa.pub >~purasi-bo/.ssh/id_rsa.pub)
	(umask 077 && cat /tmp/id_rsa.pub >~purasi-bo/.ssh/authorized_keys)
	chown purasi-bo:purasi-bo -R ~purasi-bo

create_users:
	for x in $(HOSTS); do ssh $$x $(USERADD) -G wheel,$(ISUCON_GROUP) -s /bin/zsh purasi-bo; done

rsync_users:
	for x in $(HOSTS); do rsync -a ~purasi-bo $$x:/home; done
	for x in $(HOSTS); do ssh $$x restorecon -R ~purasi-bo; done
