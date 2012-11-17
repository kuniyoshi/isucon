一人ISUCONしました
==================

構成
====

rev1, app1, db1構成です。

結果
====

    { teamid: 'team01',
      resulttime: Sat Nov 17 2012 02:12:50 GMT+0900 (JST),
      test: true,
      score: 85722,
      bench:
       { fetches: 85722,
         'max parallel': 10,
         bytes: 2939540000,
         seconds: 180,
         'mean bytes/connection': 34291.6,
         'msecs/connect': { mean: 0.522571, max: 13.853, min: 0.138 },
         'msecs/first-response': { mean: 1.46824, max: 257.717, min: 0.222 },
         response: { success: 85722, error: 0 },
         responseCode: { '200': 85722 } },
         checker:    { checker: { summary: 'success' },
         poster: { summary: 'success' } } }


    GET /
            count:  473
            sum:    8.21
            avg:    0.02
    GET /article
            count:  262
            sum:    12.26
            avg:    0.05
    GET /css
            count:  4
            sum:    0.01
            avg:    0.00
    GET /images
            count:  2
            sum:    0.00
            avg:    0.00
    GET /js 
            count:  6
            sum:    0.01
            avg:    0.00
    GET /side
            count:  477
            sum:    26.05
            avg:    0.05
    POST /comment
            count:  179
            sum:    3.60
            avg:    0.02
    POST /post
            count:  1
            sum:    0.01
            avg:    0.01

スペック
========

MacBook AirのVMware FusionでVMを3つ動かしています。

* MacBook Air

        OS: OS X 10.8.2
        CPU: 1.6 GHz Intel Core i5
        Memory: 4 GB 1333 MHz DDR3

* rev1

        OS: Scientific Linux release 6.3 (Carbon), 2.6.32-279.el6.x86_64
        CPU: 2 VCPUs
        Memory: 512 MB

* app1

        OS: Scientific Linux release 6.3 (Carbon), 2.6.32-279.el6.x86_64
        CPU: 2 VCPUs
        Memory: 512 MB

* db1

        OS: Scientific Linux release 6.3 (Carbon), 2.6.32-279.el6.x86_64
        CPU: 2 VCPUs
        Memory: 512 MB

構成の詳細
==========

HTTPフロー
----------

            +--- rev1 ---------+    +--- app1 ------------+
    HTTP -> | Varnish -> Nginx | -> | starman -- memcched |
            +------------------+    +---------------------+
                                             |
                                    +--- db1 -------------+
                                    | MySQL               |
                                    +---------------------+

rev1
----

リクエストをVarnishでうけて、ローカルのNginxにプロキシします。

Nginxはapp1のstarmanにプロキシします。

NginxがstarmanとVarnishとの間に入っているのは、ログ取得と
静的ファイル配信のためです。ESIするとVarnishが処理時間を
マイナスで報告するので、Nginxにログを任せました。

VarnishのためにOSパラメータ設定しましたので、下に書きます。

* worker threadsが1000くらいで上限になってしまうので/etc/security/limits.conf
    を変えてます。結局1000の上限は超えられませんでした。

        www             -       sigpending      16384
        www             -       nofile          16384
        www             -       nproc           32768

* TIME_WAITが4000を超えたあたりでhttp_loadがEADDRINUSEを報告するようなったので、
    tcp関連のパラメータ変えました。メモリも変えましたが、いらなかったかもしれません。

        net.ipv4.tcp_fin_timeout = 10
        net.ipv4.tcp_tw_reuse = 1
        net.ipv4.tcp_tw_recycle = 1
        net.ipv4.tcp_mem = 44736 59648 89472
        net.ipv4.tcp_wmem = 16384 16384 1908736
        net.ipv4.tcp_rmem = 16384 87380 1908736

app1
----

Server::Starterをdaemontoolsで起動して、starmanをあげています。

KossyでDBからの応答をmemcachedに保存しています。

キャッシュの更新用にgracerというサービスを定義してdaemontools
で起動しています。1秒以内の更新にかからないようにVarnishに
キャッシュ更新をリクエストしています。

db1
---

MySQLを上げているだけで、なにも変えてないです。

Varnish
-------

rev1で起動しています。変更点を下に書きます。

* VARNISH_MIN_THREADS=400
    できるだけ多くしようとして、このくらいにしました。

* VARNISH_MAX_THREADS=500
    できるだけ多くしようとして、このくらいにしました。

* ESIの有効化
    新着記事一覧を更新したとき、記事を変えていなくても、
    cssなど以外の全部のキャッシュが無効になってしまうので、
    新着記事一覧と記事とのキャッシュを分けることで
    ヒット率を高めようとしています。

* -p sess_timeout=1
    はまりました。keep aliveがあると止まるので短くしました。
    無効にするやり方が分からなかったので1秒です。

* 新しく定義したPURGEメソッドの受信
    キャッシュのTTLを1秒にします。

* 新しく定義したGRACEメソッドの受信
    キャッシュを更新します。TTLが切れていなくても更新したいとき
    に使います。

Nginx
-----

Varnishと同じく、rev1で起動しています。
変更点は特に無いです。

Isucon.pm
---------

app1で起動しています。変更点を下に書きます。

* ESIしたかったので/sideを定義して、filterは/sideだけにしました。
* コメント時に該当記事にPURGEを送るようにしました。
* 新着記事一覧のSQLを変えました。コメント時にarticle.commented_atをセットするようにしました。
* 新着記事一覧の結果をmemcachedに保存するようにしました。
    keep aliveにはまっている時にやってみたもので、ほとんど効果はないかもしれません。

感想
====

面白かったです。キャッシュ周りで勉強になることが多かったです。

Isucon.pmの方はほとんど何もしない予定でしたが、keep aliveで
はまったので、予定よりいろいろしました。

ulimitとsysctlは試行錯誤で設定しているので、余計なのがあるかもしれません。

ISUCON#2やったらISUCON#2.5書いてみようと思います。
