USERADD=/usr/sbin/useradd
ISUCON_GROUP=isucon
HOSTS="192.168.1.122 192.168.1.123 192.168.1.124"

all: prepare root rsync_root purasi-bo

root:
	mkdir /root/.ssh
	chmod 700 /root/.ssh
	cat /tmp/id_rsa >/root/.ssh/id_rsa
	chmod 600 /root/.ssh/id_rsa
	cat /tmp/id_rsa.pub >/root/.ssh/id_rsa.pub
	chmod 644 >/root/.ssh/id_rsa.pub
	cat /tmp/id_rsa.pub >/root/.ssh/authorized_keys
	chmod 600 /root/.ssh/authorized_keys

rsync_root:
	for x in $(HOSTS); do rsync -av /root/.ssh $$x:/root; done

prepare:
	yum install -y zsh

purasi-bo:
	$(USERADD) -G wheel,$(ISUCON_GROUP) -s /bin/zsh purasi-bo
	pushd ~purasi-bo
	git clone -b isucon git://github.com/kuniyoshi/dotfiles.git
	pushd dotfiles
	make install
	popd
	popd
	echo 'export GIT_AUTHOR_EMAIL=kuniyoshi@cpan.com\n''export GIT_COMMITTER_EMAIL=kuniyoshi@cpan.com\n''export EMAIL=kuniyoshi@cpan.com\n' >~purasi-bo/.secretrc


