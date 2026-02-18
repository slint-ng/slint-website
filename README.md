# slint-website

This repository hosts the files allowing to (re)build the website https://slint-ng.org and the files in `./packages`, `./installers`, `./pub`, and `./forSlackware`.

Requirements to build a local copy of the website:
* an nginx server (on Arch Linux the web root is usually `/srv/http`)
* `asciidoctor`
* `rsync`
* `git`
* a shell able to work in POSIX mode
* this repository cloned from `https://github.com/slint-ng/slint-website`
* optionally a sibling clone of `https://github.com/slint-ng/slint-translations` (if not present, `build_website.sh` clones it automatically)

To build a local copy of the website in `./website`, run from the root of this cloned directory:

`sh build_website.sh`

To deploy automatically after build, set `DEPLOY_ROOT`:

`DEPLOY_ROOT=/srv/http sh build_website.sh`

You can also change the local output directory:

`WEBSITE_DIR=/path/to/staging sh build_website.sh`

Homepage tribute snippets are loaded per locale from `doc/tribute/<locale>.adoc` with fallback to `doc/tribute/en_US.adoc`.

An nginx virtual host example is provided in `nginx/slint-ng.org.conf`.
