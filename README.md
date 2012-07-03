# JS Bin Admin

A sh(1) shell script for JS Bin administration and installation (Ubuntu).

## Usage

For usage information execute:

    ./jsbin.sh help

which shows the available commands:

<pre>
usage: jsbin.sh [OPTIONS] [ACTION [args]]

ACTIONS

  &lt;no action&gt;                           list all urls
  l[s], l[ist], s[how]  [url, ...]      list (all) urls

  f[lush]               [url, ...]      remove old revisions of (all) url(s)
  j[s]                  [url, ...]      dump JavaScript for (all) url(s)
  ht[ml]                [url, ...]      dump HTML for (all) url(s)

  m[v], ren[ame]        from to         rename url FROM to TO
  c[p], c[opy]          from to         copy url FROM to TO
  rm, del[ete]          url, ...        delete url(s)
  rm, del[ete]          '*'             delete all url(s)

  b[ackup]              [file]          dump database into FILE (jsbin-NNN.sql)
  res[tore]             [file]          restore database from FILE (jsbin-NNN.sql)
</pre>
	

## Minimal Installation (JS Bin not installed)

For database administration, it is not necessary to have JS Bin
installed.

1. Get JS Bin Admin from <https://github.com/wolfmanx/jsbin-admin.git>
   and change into the sub-directory of `jsbin-admin`:

    <pre>
    git clone https://github.com/wolfmanx/jsbin-admin.git
    cd jsbin-admin
    </pre>

2. Copy `.config.rc-default` to `.config.rc` [1] and edit your
   settings.

   The minimal set of configuration parameters are the database
   settings:

    <pre>
    DB_HOST="localhost"
    DB_USER="jsbin-user"
    DB_PASSWORD="jsbin-000"
    DB_NAME="jsbin"
    </pre>

3. Execute `./jsbin.sh` from the installation directory or call it
   from anywhere with an absolute or relative path.

[1] You can also edit `.config.rc-default` directly, if you don't care
about repository differences).

## Install JS Bin Admin wrapper

Execute (as root) the command:

    sudo ./jsbin.sh installas

This installs a wrapper for `jsbin.sh` as `<DB_NAME>-admin` in
`${BIN_DIR}`.

E.g., `DB_NAME=my_jsbin` results in `/usr/local/bin/my-jsbin-admin`.
Note, that underscores are replaced by `-`.

This step is completely optional. The script `jsbin.sh` also works, if
called with an absolute or relative pathname.

## Full JS Bin/Apache Configuration and Installation

1. In the JS Bin Admin subdirectory, get JS Bin from
   [GitHub](http://github.com).

   * If you are installing JS Bin without a subdirectory

         ROOT = `/`, e.g. `http://your.domain/`,

     the standard version at <https://github.com/remy/jsbin.git> is
     sufficient.

   * If you are installing JS Bin with a subdirectory

         ROOT = `/<your-sub-directory>/`, e.g. `http://your.domain/jsbin/`

     you can get the fork at <https://github.com/wolfmanx/jsbin.git>,
     which contains some fixes for subdirectory URLs.

     This is not necessary, if the pull request
     [#196](https://github.com/remy/jsbin/pull/196) has been accepted.

   * Or use your own version of JS Bin.

     **Hint**: Configure `JSBIN_DIR` in `.config.rc`, if you wish to
               use the configuration features of `jsbin-admin`.

2. Execute (as root) the command:

       sudo ./jsbin.sh install

   This will perform the following tasks:

   * augment JS Bin with configuration templates (`config.php.in`,
     `.htaccess.in`, ...)
   * configure JS Bin from the generic configuration templates
     according to your settings
   * compile `jsbin.<v.m.r>.js`
   * install `jsbin.sh` as `<DB_NAME>-admin` (e.g. `jsbin-admin`)
   * install a configuration file in `/etc/apache2/conf.d`
   * enable module `rewrite` in apache2
   * restart apache
   * create the MySQL database
   * create the JS Bin database user

   In order to change the configuration, the `install` command can be
   performed multiple times without affecting the data in the
   database.

## Copyright

Copyright (C) 2012, Wolfgang Scherer, <Wolfgang.Scherer at gmx.de>
Sponsored by WIEDENMANN SEILE GMBH, http://www.wiedenmannseile.de

This file is part of Wiedenmann Utilities.

See MIT-LICENSE.TXT for conditions.

<!--
:ide-menu: Emacs IDE Menu - Buffer @BUFFER@
. M-x `eIDE-menu' ()(eIDE-menu "z")

:ide: COMPILE: markdown >README-md.html
. (let ((opts "")) (compile (concat "markdown " opts " " (buffer-file-name) "  >README-md.html")))

:ide: COMPILE: markdown
. (let ((opts "")) (compile (concat "markdown " opts " " (buffer-file-name))))
-->
<!--
Local Variables:
mode: markdown
End:
-->
