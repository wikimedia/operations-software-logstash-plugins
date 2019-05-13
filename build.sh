#!/bin/bash

set -e

usage() {
    echo "Usage: $0 <version>"
    echo
    exit 1
}

if [ -z "$1" -o ! -z "$2" ]; then
    echo Wrong number of arguments
    usage
fi

VERSION=$1
IS_SNAPSHOT="$(if [[ "$VERSION" == *"-SNAPSHOT" ]]; then echo "yes"; else echo "no"; fi)"
PLUGIN_PACK="plugins-${VERSION}.zip"
PLUGIN_PACK_PATH="$(realpath target/releases)/${PLUGIN_PACK}"
LS_HOME=${LS_HOME:=/usr/share/logstash}
LS_PLUGIN="${LS_HOME}/bin/logstash-plugin"

if [ -f "$PLUGIN_PACK_PATH" -a "$IS_SNAPSHOT" = "no" ]; then
    echo Plugin pack already exists, please use a higher version number.
    usage
fi

cleanup() {
    rv=$?
    rm -f /tmp/logstash-gem-build.$$
    if [ $rv -ne 0 ]; then
        echo
        echo ------------------------
        echo BUILD FAILED
        echo
        rm -f "$PLUGIN_PACK"
    fi
    exit $rv
}
trap cleanup INT TERM EXIT

echo ------------------------
echo 'Cleanup previous builds'
echo
rm -rf target/build
rm -f "${PLUGIN_PACK_PATH}"
echo

echo ------------------------
echo Build the wikimedia gem
echo
pushd logstash-filters-wikimedia
gem build logstash-filters-wikimedia.gemspec | tee /tmp/logstash-gem-build.$$
WIKIMEDIA_GEM=$(realpath $(grep File: /tmp/logstash-gem-build.$$ | awk '{print $2}'))
if [ ! -f "${WIKIMEDIA_GEM}" ]; then
    echo Failed to locate build of logstash-filers-wikimedia gem
    exit 1
fi
popd
mkdir -p target/build/logstash
mv "${WIKIMEDIA_GEM}" target/build/logstash
echo

echo ------------------------
echo Build initial plugin pack with logstash-plugin prepare-offline-pack
echo
pushd $LS_HOME # https://github.com/logstash-plugins/logstash-filter-anonymize/issues/11

# Install first otherwize prepare-offline-pack will fail
$LS_PLUGIN install \
    logstash-filter-anonymize \
    logstash-filter-multiline \
    logstash-filter-prune \
    logstash-filter-json_encode \
    logstash-filter-truncate \
    logstash-output-sentry

$LS_PLUGIN prepare-offline-pack \
    --output "$PLUGIN_PACK_PATH" \
    logstash-filter-anonymize \
    logstash-filter-multiline \
    logstash-filter-prune \
    logstash-filter-json_encode \
    logstash-filter-truncate \
    logstash-output-sentry
popd
echo

echo ------------------------
echo Add logstash-filters-wikimedia to plugin pack
echo
pushd target/build
zip -ru "$PLUGIN_PACK_PATH" .
popd
echo

echo ------------------------
echo Link plugin pack to latest
echo
rm -f target/releases/plugins-latest.zip
ln -s ${PLUGIN_PACK} target/releases/plugins-latest.zip

echo ------------------------
echo "Build of ${PLUGIN_PACK} complete"
echo
echo "Test install with:"
echo -e "\t${LS_PLUGIN} install ${PLUGIN_PACK_PATH}"
echo
echo "${PLUGIN_PACK} is going to be uploaded to archiva"
echo "press [Ctrl]-[C] to abort or [Enter] to continue"
read

if [ "${IS_SNAPSHOT}" = "yes" ]; then
  REPO_NAME="snapshots"
else
  REPO_NAME="releases"
fi

mvn deploy:deploy-file \
	-DrepositoryId="wikimedia.${REPO_NAME}"\
	-Durl="https://archiva.wikimedia.org/repository/${REPO_NAME}" \
	-Dfile="${PLUGIN_PACK_PATH}" \
	-DgeneratePom=false \
	-DgroupId=org.wikimedia.logstash \
	-DartifactId=plugins \
	-Dversion="${VERSION}" \
	-Dpackaging=zip

