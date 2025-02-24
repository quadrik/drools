#!/bin/bash
set -euo pipefail

script_dir_path=$(cd `dirname "${BASH_SOURCE[0]}"`; pwd -P)
mvn_cmd="mvn ${BUILD_MVN_OPTS:-} ${BUILD_MVN_OPTS_QUARKUS_UPDATE:-}"
ci="${CI:-false}"

rewrite_plugin_version=4.43.0
quarkus_version=${QUARKUS_VERSION:-3.0.0.Final}

quarkus_file="${script_dir_path}/quarkus3.yml"
patch_file="${script_dir_path}"/patches/0001_before_sh.patch

rewrite=${1:-'none'}
echo "rewrite "${rewrite}

if [ "rewrite" != ${rewrite} ]; then
    echo "No rewrite to be done. Exited"
    exit 0
fi

export MAVEN_OPTS="-Xmx16192m"

echo "Update project with Quarkus version ${quarkus_version}"

set -x

if [ "${ci}" = "true" ]; then
    # In CI we need the main branch snapshot artifacts deployed locally
    ${mvn_cmd} clean install -Dquickly
fi

project_version=$(${mvn_cmd} -q -Dexpression=project.version -DforceStdout help:evaluate)

# Regenerate quarkus3 recipe
cd ${script_dir_path}
curl -Ls https://sh.jbang.dev | bash -s - jbang/CreateQuarkusDroolsMigrationRecipe.java
cd -
if [ "$(git status --porcelain ${quarkus_file})" != '' ]; then
    git add "${quarkus_file}"
    git commit -m '[Quarkus 3 migration] Update Openrewrite recipe'
fi

# Launch Quarkus 3 Openrewrite
${mvn_cmd} org.openrewrite.maven:rewrite-maven-plugin:${rewrite_plugin_version}:run \
    -Drewrite.configLocation="${quarkus_file}" \
    -DactiveRecipes=io.quarkus.openrewrite.Quarkus \
    -Drewrite.recipeArtifactCoordinates=org.kie:jpmml-migration-recipe:"${project_version}" \
    -Denforcer.skip \
    -fae \
    -Dexclusions=**/target \
    -DplainTextMasks=**/kmodule.xml

# Update dependencies with Quarkus 3 bom
${mvn_cmd} \
    -pl :drools-build-parent \
    -DremotePom=io.quarkus:quarkus-bom:${quarkus_version} \
    -DupdatePropertyVersions=true \
    -DupdateDependencies=true \
    -DgenerateBackupPoms=false \
    versions:compare-dependencies

# Create the `patches/0001_before_sh.patch` file
git add .
git diff --cached > "${patch_file}"
git reset

# Commit the change on patch
if [ "$(git status --porcelain ${patch_file})" != '' ]; then
    git add "${patch_file}"
    git commit -m '[Quarkus 3 migration] Updated Openrewrite patch'
fi

# Reset all other changes as they will be applied next by the `patches/0001_before_sh.patch` file
git reset --hard