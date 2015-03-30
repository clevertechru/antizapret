#!/usr/bin/env sh

LOC="$(dirname ${0})"
. "${LOC}"/common.sh

LIST='/etc/nginx/conf.d/govblock.conf'
BLOCKER='/etc/nginx/block_gov'
REDIRECT_URL="${REDIRECT_URL:-/restrict_access.html;"
SITES=/etc/nginx/sites-available/*

# create config file with rules
LIST_PARENT=`dirname ${LIST}`
mkdir -p "${LIST_PARENT}"
echo '# WARNING! This file was generated. Do not change!' > "${LIST}"
echo 'geo $gov_user {' >> "${LIST}"
echo 'default 0;' >> "${LIST}"
getblacklist_all | while read net; do
    echo "${net} 1;" >> "${LIST}"
done
echo '}' >> "${LIST}"

# create config file which does actual blocking
# visitors are redirected to $REDIRECT_URL
echo '# WARNING! This file was generated. Do not change!' > "${BLOCKER}"
echo 'if ($gov_user = 1) {' >> "${BLOCKER}"
echo "#rewrite ^ ${REDIRECT_URL};" >> "${BLOCKER}"
echo "return 404;" >> "${BLOCKER}"
echo '}' >> "${BLOCKER}"

# include blocker configuration file from all sites
# finds only '^server {' server declarations
for site in $SITES; do
    if (! grep -q "${BLOCKER}" "${site}" ); then
        sed "/^server {/ainclude ${BLOCKER};" -i "${site}";
    fi
done

