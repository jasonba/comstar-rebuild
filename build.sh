#!/bin/bash

printf "Building ... \n"
REBUILD_TARBALL=comstar-rebuild.tar

tar cf $REBUILD_TARBALL README comstar-rebuild.sh create-initiator.pl create-lu.pl hg.pl target.pl tg.pl views.pl
gzip -f $REBUILD_TARBALL

printf "done\n"
echo "tarball is here: ${REBUILD_TARBALL}.gz"
