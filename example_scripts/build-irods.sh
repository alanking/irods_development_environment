#! /bin/bash -ex

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
irods_builddir="${builddir}"/irods/"${branch_platform_subdir}"/irods
icommands_builddir="${builddir}"/irods/"${branch_platform_subdir}"/icommands
irods_packagedir="${builddir}"/irods_packages/"${branch_platform_subdir}"
externals_packagedir="${builddir}"/externals/"${branch_platform_subdir}"

sourcedir=/home/alanking/hdd/dev
irods_sourcedir="${sourcedir}"/irods
icommands_sourcedir="${sourcedir}"/irods_client_icommands

docker run --rm \
           -v ${irods_sourcedir}:/irods_source:ro \
           -v ${irods_builddir}:/irods_build \
           -v ${icommands_sourcedir}:/icommands_source:ro \
           -v ${icommands_builddir}:/icommands_build \
           -v ${irods_packagedir}:/irods_packages \
           -v ${externals_packagedir}:/irods_externals_packages \
           irods-core-builder-m:"${PLATFORM}"-"${VERSION}" --ninja --debug $@
