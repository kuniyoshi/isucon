package Isucon;
use utf8;
use strict;
use warnings;
use autodie qw( open close );
use DBI;
use JSON;
use Kossy;
use Cache::Memcached;

my $MEMD = Cache::Memcached->new(
    servers => [ "192.168.1.122:11211" ],
);

our $VERSION = 0.02;

sub config {
    my $self = shift;

    return $self->{_config} ||= do {
        open my $fh, '<', $self->root_dir . '/../config/hosts.json';
        my $json = do { local $/; <$fh> };
        close $fh;
        decode_json( $json );
    };
}

sub dbh {
    my $self   = shift;
    my $config = $self->config;
    my $host   = $config->{servers}{database}[0] || '127.0.0.1';

    return DBI->connect_cached(
        "dbi:mysql:isucon;host=$host",
        'isuconapp',
        'isunageruna',
        {
            RaiseError          => 1,
            PrintError          => 0,
            ShowErrorStatement  => 1,
            AutoInactiveDestroy => 1,
            mysql_enable_utf8   => 1,
        },
    );
}

filter 'recent_commented_articles' => sub {
    my $app = shift;
    return sub {
        my( $self, $c ) = @_;
        my $cache = $MEMD->get( "recent_commented_articles" );
        unless ( $cache ) {
            $cache = $self->dbh->selectall_arrayref( <<END_SQL, { Slice => {} } );
SELECT id, title FROM article ORDER BY commented_at DESC LIMIT 10
END_SQL
            $MEMD->set( "recent_commented_articles", $cache );
        }
        $c->stash->{recent_commented_articles} = $cache;
#SELECT a.id, a.title FROM comment c INNER JOIN article a ON c.article = a.id GROUP BY a.id ORDER BY MAX(c.created_at) DESC LIMIT 10
        $app->( $self, $c );
    };
};

get '/' => sub {
    my( $self, $c ) = @_;
    my $rows = $self->dbh->selectall_arrayref( <<END_SQL, { Slice => {} } );
SELECT id, title, body, created_at FROM article ORDER BY id DESC LIMIT 10
END_SQL
    return $c->render( 'index.tx', { articles => $rows } );
};

get '/article/:articleid' => sub {
    my( $self, $c ) = @_;
    my $article = $self->dbh->selectrow_hashref( <<END_SQL, { }, $c->args->{articleid} );
SELECT id, title, body, created_at FROM article WHERE id=?
END_SQL
    my $comments
        = $self->dbh->selectall_arrayref( <<END_SQL, { Slice => {} }, $c->args->{articleid} );
SELECT name, body, created_at FROM comment WHERE article = ? ORDER BY id
END_SQL
    return $c->render( 'article.tx', { article => $article, comments => $comments } );
};

get '/post' => sub {
    my( $self, $c ) = @_;
    return $c->render( 'post.tx' );
};

post '/post' => sub {
    my( $self, $c ) = @_;
    my $sth = $self->dbh->prepare( 'INSERT INTO article SET title = ?, body = ?' );
    $sth->execute( $c->req->param( 'title' ), $c->req->param( 'body' ) );
    return $c->redirect( $c->req->uri_for( '/' ) );
};

post '/comment/:articleid' => sub {
    my( $self, $c ) = @_;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare( <<END_SQL );
INSERT INTO comment SET article = ?, name =?, body = ?
END_SQL
    $sth->execute(
        $c->args->{articleid},
        $c->req->param( 'name' ),
        $c->req->param( 'body' ),
    );

    my $comment_id = $dbh->{mysql_insertid};
    my $commented_at = do {
        $sth = $dbh->prepare( "SELECT created_at FROM comment WHERE id = ?" );
        $sth->execute( $comment_id );
        $sth->fetch->[0];
    };
    my $article_id = $c->args->{articleid};
    $sth = $dbh->prepare( "UPDATE article SET commented_at = ? WHERE id = ?" );
    $sth->execute( $commented_at, $article_id );

$MEMD->set( "recent_commented_articles", q{} );

use Furl;
my $ua = Furl->new;
my $url = "http://192.168.1.121/article/$article_id";
my $res = $ua->request(
    method => "PURGE",
    url    => $url,
);
warn $res->code, " - PURGE $url";

    return $c->redirect( $c->req->uri_for( '/article/' . $c->args->{articleid} ) );
};

get '/side' => [ qw/recent_commented_articles/ ] => sub {
    my( $self, $c ) = @_;
    return $c->render( 'side.tx' );
};

1;
