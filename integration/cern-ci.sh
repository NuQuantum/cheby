#!/bin/sh

# Exit in case of error
set -e

# Use the right python tool.
. /acc/local/share/python/L867/setup.sh
python -V

# Check the variable is set
[ x"$CI_COMMIT_SHORT_SHA" != x ] || exit 1

localdir=/opt/home/cheby

base_destdir=/acc/local/share/ht_tools/noarch/cheby
suffix=$CI_COMMIT_SHORT_SHA
destdir=$base_destdir/cheby-$suffix
prefix=$destdir/lib/python3.6/site-packages/
mkdir -p $prefix

export PYTHONPATH=$PYTHONPATH:$prefix
python3 ./setup.py install --prefix $destdir

# Update cheby-latest link
cd $base_destdir
ln -sfn cheby-$suffix cheby-latest

# Remove the old version, unless it is the same as the current one
# (could happen when re-running CI/CD: there is no new version and
#  the current one shouldn't be removed).
if [ -f last ]; then
    old=$(cat last)
    if [ "$old" != "$suffix" ] then
       rm -rf ./cheby-$old
    fi
fi
echo $suffix > last

#############
# DFS update
echo "$DFS_PASSWORD" | kinit cheby@CERN.CH 2>&1 > /dev/null

# Create an archive
tarfile="$localdir/cheby-${suffix}.tar"
tar cvf $tarfile cheby-$suffix

# Deploy it
smbclient -k //cerndfs.cern.ch/dfs/Applications/Cheby -Tx $tarfile

# Remove old version
smbclient -k //cerndfs.cern.ch/dfs/Applications/Cheby -c "rename cheby-latest cheby-old; rename cheby-$suffix cheby-latest; deltree cheby-old"

rm -f $tarfile

kdestroy
