#! /bin/bash -ex

# The calling script must define $PLUGIN, $PLATFORM, $VERSION, and $BRANCH

if [[ -z ${PLUGIN} ]]; then
    echo "\$PLUGIN not defined"
    exit 1
fi

if [[ -z ${PLATFORM} ]]; then
    echo "\$PLATFORM not defined"
    exit 1
fi

if [[ -z ${VERSION} ]]; then
    echo "\$VERSION not defined"
    exit 1
fi

if [[ -z ${BRANCH} ]]; then
    echo "\$BRANCH not defined"
    exit 1
fi

branch_platform_subdir="${BRANCH}"/"${PLATFORM}"-"${VERSION}"

builddir=/home/alanking/hdd/builds
plugin_builddir="${builddir}"/irods_plugins/"${PLUGIN}"/"${branch_platform_subdir}"
plugin_packagedir="${builddir}"/irods_plugin_packages/"${PLUGIN}"/"${branch_platform_subdir}"
externals_packagedir="${builddir}"/externals/"${branch_platform_subdir}"

# NOTE: The build hook needs a "root" directory, so don't include the platform here as it
# has its own system for package discovery and installation.
irods_packagedir="${builddir}"/irods_packages/"${BRANCH}"

sourcedir=/home/alanking/hdd/dev
plugin_sourcedir="${sourcedir}"/"${PLUGIN}"

docker run --rm \
           -v ${plugin_sourcedir}:/irods_plugin_source:ro \
           -v ${plugin_builddir}:/irods_plugin_build \
           -v ${plugin_packagedir}:/irods_plugin_packages \
           -v ${irods_packagedir}:/irods_packages:ro \
           -v ${externals_packagedir}:/externals:ro \
           irods-plugin-builder-m:${PLATFORM}-${VERSION} --build_directory /irods_plugin_build \
                                                         --output_root_directory /irods_plugin_packages
                                                         #--externals_packages_directory /externals
