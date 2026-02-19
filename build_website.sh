#!/bin/sh
# Run this script from  the root of the clone of:
# https://github.com/slint-ng/slint-website

# The whole website accessed from https://slint-ng.org can be rebuilt locally after an update.
# A local staged copy is always written in $WEBSITE_DIR.
# Optionally, if DEPLOY_ROOT is set, the script rsyncs $WEBSITE_DIR to DEPLOY_ROOT.
# All pages are in folders by language, not in the web site directory.
# The header of most pages include the list of languages in which it is available
# This is true for: HandBook.html, home.html, news.html, support.html and wiki.html
#
# If a page is not translated in a given language, it is displayed in English
# The list of languages will not be included in the header of non translated
# pages, currently translate.html rm -rf slint-translations and
# internationalization_and_localization_of_shell_scripts.html
# All pages include a header with links to:
# Home Documentation Download Support Translate Wiki
# with the exception of pages included in the archived old website like
# https://slint-ng.org/old/index.html

# PO files use the ll_TT scheme, but unless there be several locales per language,
# we store the web pages in directories named $ll the per language directories.
# We build separately headers files for the translated files, which include a line
# of languages in other languages in which each page is available.
# To select the languages to include we need to know in which languages each page
# has been translated. 

# Before running this script, insure that all files in asciidoc format in
# sub-directories of:
# https://github.com/slint-ng/slint-translations/translations/
# be up to date running from its root po4a with as argument the relevant
# .cfg file in the `configuration` folder and the --no-update option.

# Most sources pages, in asciidoc format and their translations are stored in
# https://github.com/slint-ng/slint-translations/ that we clone here
CWD="$(pwd)"
TRANSLATIONS_REPO="https://github.com/slint-ng/slint-translations.git"
TRANSLATIONS_LOCAL_CLONE="${TRANSLATIONS_LOCAL_CLONE:-$CWD/../slint-translations}"
TRANSLATIONS_MIRROR="${TRANSLATIONS_MIRROR:-/data/github/slint-translations}"
WEBSITE_DIR="${WEBSITE_DIR:-$CWD/website}"
DEPLOY_ROOT="${DEPLOY_ROOT:-}"
TRIBUTE_DIR="${TRIBUTE_DIR:-$CWD/doc/tribute}"
TRIBUTE_FALLBACK="${TRIBUTE_FALLBACK:-$TRIBUTE_DIR/en_US.adoc}"
DEFAULT_LANG="${DEFAULT_LANG:-en}"

web_lang_dir() {
	llTT="$1"
	case "$llTT" in
		pt_BR) printf '%s\n' "pt_BR" ;;
		*) printf '%s\n' "${llTT%_*}" ;;
	esac
}

patch_homepage_maintainer() {
	homeFile="$1"
	[ -f "$homeFile" ] || return 0
	sed -i \
	-e "s@Maintainer: Didier Spaier\\.@Maintainer: Tony Seth and the Slint team.@g" \
	-e "s@Mainteneur : Didier Spaier\\.@Mainteneur : Tony Seth et l'équipe Slint.@g" \
	-e "s@Entwickler: Didier Spaier\\.@Entwickler: Tony Seth und das Slint-Team.@g" \
	-e "s@Συντηρητής: Didier Spaier\\.@Συντηρητής: Tony Seth και η ομάδα Slint.@g" \
	-e "s@Manutentore: Didier Spaier\\.@Manutentore: Tony Seth e il team Slint.@g" \
	-e "s@Onderhouden door Didier Spaier\\.@Onderhouden door Tony Seth en het Slint-team.@g" \
	-e "s@Criador e responsável: Didier Spaier\\.@Criador e responsável: Tony Seth e a equipe Slint.@g" \
	-e "s@Сопровождающий: Didier Spaier\\.@Сопровождающий: Tony Seth и команда Slint.@g" \
	-e "s@Underhållare: Didier Spaier\\.@Underhållare: Tony Seth och Slint-teamet.@g" \
	"$homeFile"
}

patch_homepage_packages_link() {
	homeFile="$1"
	[ -f "$homeFile" ] || return 0
	sed -i \
	-e "s|http://slackware.uk/slint/x86_64/slint-15.0/slint.txt|https://slackware.uk/slint/|g" \
	-e "s|https://slackware.uk/slint/x86_64/slint-15.0/slint.txt|https://slackware.uk/slint/|g" \
	-e "s|http://slackware.uk/slint/x86_64/slint-15.0/extra.txt|https://slackware.uk/slint/x86_64/slint-15.0/packages/|g" \
	-e "s|https://slackware.uk/slint/x86_64/slint-15.0/extra.txt|https://slackware.uk/slint/x86_64/slint-15.0/packages/|g" \
	-e "s|http://slackware.se/slint/x86_64/slint-15.0/extra.txt|https://slackware.uk/slint/x86_64/slint-15.0/packages/|g" \
	-e "s|https://slackware.se/slint/x86_64/slint-15.0/extra.txt|https://slackware.uk/slint/x86_64/slint-15.0/packages/|g" \
	"$homeFile"
}

patch_legacy_contacts() {
	htmlFile="$1"
	[ -f "$htmlFile" ] || return 0
	sed -i \
	-e "s|dididieratslintdotfr|slint@freelists.org|g" \
	-e "s|didieratslintdotfr|slint@freelists.org|g" \
	"$htmlFile"
}

patch_footer_github_link() {
	htmlFile="$1"
	[ -f "$htmlFile" ] || return 0
	if grep -q 'GitHub: <a href="https://github.com/slint-ng">' "$htmlFile"; then
		return 0
	fi
	sed -i '/<div id="footer-text">/a\
GitHub: <a href="https://github.com/slint-ng">https://github.com/slint-ng</a><br>' "$htmlFile"
}

rm -rf "$CWD"/slint-translations
if [ -d "$TRANSLATIONS_LOCAL_CLONE" ]; then
	cp -r "$TRANSLATIONS_LOCAL_CLONE" "$CWD"/slint-translations || exit 1
elif [ -d "$TRANSLATIONS_MIRROR" ]; then
	cp -r "$TRANSLATIONS_MIRROR" "$CWD"/slint-translations || exit 1
else
	git clone "$TRANSLATIONS_REPO" "$CWD"/slint-translations || exit 1
fi

rm -rf wip/*
mkdir -p wip/html/doc
WIP="$CWD"/wip
rm -rf tmp/*
mkdir -p tmp/headers tmp/headers_wiki
TMP="$CWD"/tmp
SLINTDOCS="$CWD/slint-translations"

header_HandBook() {
	# We append to each file in "$CWD"/headers a list of languages in which
	# HandBook is available, as found in "$SLINTDOCS"/translations/HandBook
	cp "$SLINTDOCS"/sources/HandBook/HandBook.adoc \
	"$SLINTDOCS"/translations/HandBook/en_US.HandBook.adoc || exit
	langs="$(find "$SLINTDOCS"/translations/HandBook -name  "*adoc"|sed 's#.*/##'|cut -d_ -f1)"
	header_HandBook="$(echo "$langs"|sort|while read -r i; do echo "* link:../$i/HandBook.html[${i#./}] "; done)"
	echo "$header_HandBook" > "$TMP"/header_HandBook
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/header_HandBook "$CWD"/headers/bottom > "$TMP"/headers/"$i"
	done
	)
}

header_support() {
	# We append to each file in "$CWD"/headers a list of languages in which
	# HandBook is available, as found in "$SLINTDOCS"/translations/HandBook
	# as the support.html is extracted from HandBool.html 
	cp "$SLINTDOCS"/sources/HandBook/HandBook.adoc \
	"$SLINTDOCS"/translations/HandBook/en_US.HandBook.adoc || exit
	langs="$(find "$SLINTDOCS"/translations/HandBook -name  "*adoc"|sed 's#.*/##'|cut -d_ -f1)"
	header_support="$(echo "$langs"|sort|while read -r i; do echo "* link:../$i/support.html[${i#./}] "; done)"
	echo "$header_support" > "$TMP"/header_support
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/header_support "$CWD"/headers/bottom > "$TMP/headers/$i"
	done
	)
}

header_homepage() {
	# We append to each file in "$CWD"/headers a list of languages in which
	# homepage is available, as found in "$SLINTDOCS"/translations/homepage
	cp "$SLINTDOCS"/sources/homepage/homepage.adoc \
	"$SLINTDOCS"/translations/homepage/en_US.homepage.adoc || exit
	langs="$(find "$SLINTDOCS"/translations/homepage -name  "*adoc"|sed 's#.*/##'|cut -d_ -f1)"
	header_homepage="$(echo "$langs"|sort|while read -r i; do echo "* link:../$i/home.html[${i#./}] "; done)"
	echo "$header_homepage" > "$TMP"/header_homepage
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/header_homepage "$CWD"/headers/bottom > "$TMP"/headers/"$i"
	done
	)
}

header_news() {
	# We append to each file in "$CWD"/headers a list of languages in which
	# news is available, as found in "$SLINTDOCS"/translations/news
	cp "$SLINTDOCS"/sources/news/news.adoc \
	"$SLINTDOCS"/translations/news/en_US.news.adoc || exit
	langs="$(find "$SLINTDOCS"/translations/news -name  "*adoc"|sed 's#.*/##'|cut -d_ -f1)"
	header_news="$(echo "$langs"|sort|while read -r i; do echo "* link:../$i/news.html[${i#./}] "; done)"
	echo "$header_news" > "$TMP"/header_news
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/header_news "$CWD"/headers/bottom > "$TMP"/headers/"$i"
	done
	)
}

header_wiki() {
	# We consider that the wiki has been translated in a given language as soon
	# as one of its articles has been translated in this langage.
	cd "$SLINTDOCS/translations/wiki" || exit
	articles="$(find . -type d -mindepth 1 -maxdepth 1|sed 's#..##'|sort)"
	echo "$articles"|while read -r article; do 
		cp "$SLINTDOCS/sources/wiki/$article/${article}.adoc" \
			"$article/en_US.${article}.adoc" || exit
	done
	# We display in English the non translated articles.
	locales="$(find . -name "*.adoc"|sed 's#.*/##'|cut -d. -f1|sort|uniq)"
	langs="$(echo "$locales"|cut -d_ -f1)"
	for ll_TT in $locales; do		
		echo "$articles"|while read -r article; do
		if [ ! -f "$article/${ll_TT}.${article}.adoc" ]; then
			cp "$article/en_US.${article}.adoc" \
			"$article/${ll_TT}.${article}.adoc" || exit
		fi
		done
	done
	header_wiki="$(echo "$langs"|sort|while read -r i; do echo "* link:../$i/wiki.html[${i#./}] "; done)"
	echo "$header_wiki"|sort|uniq > "$TMP"/headers_wiki/header_wiki
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/headers_wiki/header_wiki "$CWD"/headers/bottom_wiki > "$TMP"/headers_wiki/"$i"
		# Rename "$ll_TT.header.adoc" as "ll_TT.wiki.adoc" as initially they
		# are identical.
		rename header wiki "$TMP"/headers_wiki/"$i"
	done
	# We have now in "$TMP"/headers_wiki/ the localized wiki pages, without
	# the links to the included articles that we will add in feed_wiki.
	)
}

feed_HandBook14_2_1 () {
	cd "$SLINTDOCS"/translations/HandBook14.2.1 || exit 1
	# Rranslations of the old HandBook being frozen the list of langages is fix. 
	langs=$(echo "de el en es fr it ja nl pl pt pt_BR ru sv uk"|sed "s/ /\n/g")
	header_oldhandbook="$(echo "$langs"|while read -r i; do echo "* link:../$i/oldHandBook.html[${i#./}] "; done)"
	echo "$header_oldhandbook" > "$TMP"/header_oldhandbook
	(cd "$CWD"/headers || exit
	for i in *.adoc; do
		cat "$i" "$TMP"/header_oldhandbook "$CWD"/headers/bottom > "$TMP"/headers/"$i"
	done
	)
	find . -name "*.adoc"|sed 's#..##'|while read -r i; do
		ll_TT="${i%.*.*}"
		cat "$TMP/headers/${ll_TT}.header.adoc" "$i" > bif
		mv bif "$i"
		ll="$(web_lang_dir "$ll_TT")"
		mkdir -p "$WIP"/html/"$ll"
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
		copycss="$CWD"/css/slint.css -D "$WIP" -a doctype=book "$i" -o bof
		sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
		"$WIP"/bof > "$WIP"/html/"$ll"/HandBook.html
		patch_legacy_contacts "$WIP"/html/"$ll"/HandBook.html
				if [ "$ll_TT" = "pt_BR" ]; then
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
			copycss="$CWD/css/slint.css" -D "$WIP" -a doctype=book \
			"${ll_TT}.oldHandBook.adoc" -o "$WIP"/html/"$ll_TT"/oldHandBook.html
			sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
			"$WIP"/html/"$ll_TT"/oldHandBook.html
			patch_legacy_contacts "$WIP"/html/"$ll_TT"/oldHandBook.html
		else
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
			copycss="$CWD/css/slint.css" -D "$WIP" -a doctype=book \
			"${ll_TT}.oldHandBook.adoc" -o "$WIP"/html/"$ll"/oldHandBook.html
			sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
			"$WIP"/html/"$ll"/oldHandBook.html
			patch_legacy_contacts "$WIP"/html/"$ll"/oldHandBook.html
		fi
	done
}	

feed_HandBook() {
	( cd "$SLINTDOCS"/translations/HandBook || exit 1
	cp "$SLINTDOCS"/sources/HandBook/HandBook.adoc en_US.HandBook.adoc || exit
	# list the locales in which a translation of the HandBook is available.
	langs="$(find . -name  "*adoc"|sed 's#..##'|cut -d_ -f1)"
	find . -name "*.adoc"|sed 's#..##'|while read -r i; do
		ll_TT="${i%.*.*}"
		cat "$TMP/headers/${ll_TT}.header.adoc" "$i" > bif
		mv bif "$i"
		ll="$(web_lang_dir "$ll_TT")"
		mkdir -p "$WIP"/html/"$ll"
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
		copycss="$CWD"/css/slint.css -D "$WIP" -a doctype=book "$i" -o bof
		sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
		"$WIP"/bof > "$WIP"/html/"$ll"/HandBook.html
		patch_legacy_contacts "$WIP"/html/"$ll"/HandBook.html
	done
	)
}

feed_support() {
	( cd "$SLINTDOCS"/translations/HandBook || exit 1
	cp "$SLINTDOCS"/sources/HandBook/HandBook.adoc en_US.HandBook.adoc || exit
	# The Support page is just an extract of the HandBook, so list
	# the locales in which a translation of the HandBook is available.
	langs="$(find . -name  "*adoc"|sed 's#..##'|cut -d_ -f1)"
	find . -name "*.adoc"|sed 's#..##'|while read -r i; do
		ll_TT="${i%.*.*}"
		ll="$(web_lang_dir "$ll_TT")"
		# We convert the headers level 2 of the HandBook to level 1 in Support
		# hence s@===@==@
		sed -n "\@// Support@,\@// Acknowledgments@p" "$i"|head -n -1  \
		| sed "s@// .*@[.debut]@;s@===@==@" > "$WIP/${ll_TT}.support.part.adoc"	
		mkdir -p "$WIP"/html/"$ll"
		cat "$TMP"/headers/"$ll_TT".header.adoc "$WIP"/"${ll_TT}".support.part.adoc \
		> "$WIP"/"${ll_TT}".support.adoc
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
		copycss="$CWD"/css/slint.css \
		-D "$WIP" -a doctype=book "$WIP/${ll_TT}.support.adoc" -o bof
		sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
		"$WIP"/bof > "$WIP"/html/"$ll"/support.html
		patch_legacy_contacts "$WIP"/html/"$ll"/support.html
	done
	)
}

feed_homepage() {
	( cd "$SLINTDOCS"/translations/homepage || exit 1
	cp "$SLINTDOCS"/sources/homepage/homepage.adoc en_US.homepage.adoc || exit
	# list the locales in which a translation of the homepage is available.
	langs="$(find . -name  "*adoc"|sed 's#..##'|cut -d_ -f1)"
	find . -name "*.adoc"|sed 's#..##'|while read -r i; do
		ll_TT="${i%.*.*}"
		ll="$(web_lang_dir "$ll_TT")"
		tributeFile="$TRIBUTE_DIR/$ll_TT.adoc"
		if [ ! -f "$tributeFile" ]; then
			tributeFile="$TRIBUTE_DIR/$ll.adoc"
		fi
		if [ ! -f "$tributeFile" ]; then
			tributeFile="$TRIBUTE_FALLBACK"
		fi
		if [ -f "$tributeFile" ]; then
			cat "$TMP/headers/${ll_TT}.header.adoc" "$i" "$tributeFile" > bif
		else
			cat "$TMP/headers/${ll_TT}.header.adoc" "$i" > bif
		fi
		mv bif "$i"
		mkdir -p "$WIP"/html/"$ll"
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
			copycss="$CWD"/css/slint.css -D "$WIP" -a doctype=book "$i" -o bof
			sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
			"$WIP"/bof > "$WIP"/html/"$ll"/home.html
			patch_homepage_maintainer "$WIP"/html/"$ll"/home.html
			patch_homepage_packages_link "$WIP"/html/"$ll"/home.html
		done
		)
}

feed_news() {
	( cd "$SLINTDOCS"/translations/news || exit 1
	cp "$SLINTDOCS"/sources/news/news.adoc en_US.news.adoc || exit
	# list the locales in which a translation of the news is available.
	langs="$(find . -name  "*adoc"|sed 's#..##'|cut -d_ -f1)"
	find . -name "*.adoc"|sed 's#..##'|while read -r i; do
		ll_TT="${i%.*.*}"
		ll="$(web_lang_dir "$ll_TT")"
		cat "$TMP/headers/${ll_TT}.header.adoc" "$i" > bif
		mv bif "$i"
		#  echo "$ll_TT" >> "$WIP"/languages ?
		mkdir -p "$WIP"/html/"$ll"
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
		copycss="$CWD"/css/slint.css -D "$WIP" -a doctype=book "$i" -o bof
		sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
		"$WIP"/bof > "$WIP"/html/"$ll"/news.html
	done
	)
}


feed_wiki() {
	cd "$SLINTDOCS"/translations/wiki || exit 1
	articles="$(find . -type d -mindepth 1 -maxdepth 1|sed 's#..##'|sort)"
	echo "$articles"|while read -r article; do 
		cp "$SLINTDOCS/sources/wiki/$article/${article}.adoc" \
			"$article/en_US.${article}.adoc" || exit
	done
	# List all locales of translations of articles included in the wiki
	locales="$(find . -name "*.adoc"|sed 's#.*/##'|cut -d. -f1|sort|uniq)"
	# For each article of the wiki, if a translation in a given locale is not
	# available, replace it by en_US.
	for article in $articles; do
		mkdir -p "$TMP/$article"
		for ll_TT in $locales; do
			ll="$(web_lang_dir "$ll_TT")"
			mkdir -p "$WIP"/html/"$ll"
			echo "include::$SLINTDOCS/translations/wiki/$article/${ll_TT}.${article}.adoc[ ]" \
			>>"$TMP"/headers_wiki/"$ll_TT".wiki.adoc
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
			copycss="$CWD"/css/slint.css -D "$WIP" -a doctype=book \
			"$TMP/headers_wiki/${ll_TT}.wiki.adoc"  -o "$TMP"/bof
			sed 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
			"$TMP"/bof > "$WIP"/html/"$ll"/wiki.html
		done
	done
	cd "$CWD" || exit
}

# Note: if feed_HandBook14_2_1 is run after feed_HandBook the pages Handbook.html
# are the same as oldHandBook.html. I did not find why yet - Didier 18 June 2025
feed_HandBook14_2_1
header_support
feed_support
header_HandBook
feed_HandBook
header_homepage
feed_homepage
header_news
feed_news
header_wiki
feed_wiki
# If a page is not translated for a language, publish a fallback.
# Prefer pt for pt_BR, else fallback to English.
for headerPath in "$CWD"/headers/*.header.adoc; do
	llTT="$(basename "$headerPath" .header.adoc)"
	lang="$(web_lang_dir "$llTT")"
	langDir="$WIP"/html/"$lang"
	mkdir -p "$langDir"
	for page in home news support wiki; do
		target="$langDir/$page.html"
		if [ ! -f "$target" ]; then
			if [ "$lang" = "pt_BR" ] && [ -f "$WIP/html/pt/$page.html" ]; then
				cp "$WIP/html/pt/$page.html" "$target"
			elif [ -f "$WIP/html/en/$page.html" ]; then
				cp "$WIP/html/en/$page.html" "$target"
			fi
		fi
	done
done

# Create a root index that redirects to the default language home page.
if [ ! -f "$WIP/html/$DEFAULT_LANG/home.html" ]; then
	DEFAULT_LANG="en"
fi
cat > "$WIP/html/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Slint</title>
  <meta http-equiv="refresh" content="0; url=/$DEFAULT_LANG/home.html">
</head>
<body>
  <p>Redirecting to <a href="/$DEFAULT_LANG/home.html">/$DEFAULT_LANG/home.html</a>.</p>
</body>
</html>
EOF
# 
cp "$CWD"/doc/*.png "$WIP"/html/doc/
asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
copycss="$CWD"/css/slint.css -D "$WIP" "$CWD"/doc/translate_slint.adoc \
-o "$WIP"/html/doc/translate_slint.html
sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/"toc"/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' \
"$WIP"/html/doc/translate_slint.html
asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
copycss="$CWD"/css/slint.css -D "$WIP" \
"$CWD"/doc/internationalization_and_localization_of_shell_scripts.adoc -o "\
$WIP"/html/doc/internationalization_and_localization_of_shell_scripts.html
asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a \
copycss="$CWD"/css/slint.css -D "$WIP" \
"$CWD"/doc/shell_and_bash_scripting.adoc -o "$WIP"/html/doc/shell_and_bash_scripting.html
cp "$WIP"/html/doc/shell_and_bash_scripting.html "$WIP"/html/doc/shell_and_bash_scripts.html || exit 1
cp -r "$CWD"/css "$WIP"/html
find "$WIP"/html -type f -name "*.html" | while read -r htmlFile; do
	patch_footer_github_link "$htmlFile"
done
# Publish the archived old website so links do not fall into the refresh fallback.
mkdir -p "$WIP"/html/old
rsync -a "$CWD"/old/ "$WIP"/html/old/ || exit 1
rm -rf "$WEBSITE_DIR"
mkdir -p "$WEBSITE_DIR"
rsync --verbose -avP -H --delete-after "$CWD"/wip/html/ "$WEBSITE_DIR"/ || exit 1
if [ -n "$DEPLOY_ROOT" ]; then
	if [ -d "$DEPLOY_ROOT" ] && [ -w "$DEPLOY_ROOT" ]; then
		rsync --verbose -avP --exclude-from="$CWD"/exclude -H --delete-after \
		 "$WEBSITE_DIR"/ "$DEPLOY_ROOT"/
	else
		printf '%s\n' "Deployment skipped. DEPLOY_ROOT is not a writable directory: $DEPLOY_ROOT"
	fi
else
	printf '%s\n' "Website built in $WEBSITE_DIR"
fi
rm -rf "$CWD"/homepage "$CWD"/wiki "$CWD"/HandBook "$CWD"/HandBook14.2.1 "$CWD"/news
# run from the VPS
# su
# sh rsync_website
