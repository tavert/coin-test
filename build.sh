#!/bin/sh
# linux build

COIN_PROJECT=CoinUtils
PROJECT_VERSION=trunk

# this script could also be useful outside of a wercker context...
if test -z "$WERCKER_CACHE_DIR"; then
  WERCKER_CACHE_DIR=$HOME
fi

# install prerequisites
if ! test -L /var/cache/apt/archives; then
# link apt-get cache into WERCKER_CACHE_DIR
  mkdir -p $WERCKER_CACHE_DIR/apt-get
  sudo rm -r /var/cache/apt/archives
  sudo ln -s $WERCKER_CACHE_DIR/apt-get /var/cache/apt/archives
fi
sudo apt-get update -qq
sudo apt-get install gfortran subversion ruby clang
sudo gem install gist

# download COIN source, will do an update if already downloaded
svn co -q --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$COIN_PROJECT/$PROJECT_VERSION $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION
cd $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION
# do svn update in case of connectivity trouble during checkout (seems to only be a travis problem)
#svn update --non-interactive --trust-server-cert

# download third-party source
for i in `ls ThirdParty/*/get.*`; do
  cd `dirname $i`
  ./`basename $i`
  cd ../..
done

# add a newline at end of CoinUtils/src/CoinLpIO.hpp until fixed
mkdir -p CoinUtils/src
#echo "" >> CoinUtils/src/CoinLpIO.hpp

# default gcc build
# uncomment one of the below cleanup lines if potential problems from past builds (config changes, etc)
#rm build/config.cache || true
#rm -rf build || true
mkdir -p build
cd build
do_gist=no
../configure -C || do_gist=yes
if test $do_gist = yes; then
  echo "CONFIG.LOG UPLOADED TO URL:"
  gist config.log
  exit 1
# should also upload subfolder config.log's, if I can get that to work
fi
make all -j4
make install
make test

cd ..

# clang build
# uncomment one of the below cleanup lines if potential problems from past builds (config changes, etc)
#rm build_clang/config.cache || true
#rm -rf build_clang || true
mkdir -p build_clang
cd build_clang
do_gist=no
../configure -C CC=clang CXX=clang++ || do_gist=yes
if test $do_gist = yes; then
  echo "CONFIG.LOG UPLOADED TO URL:"
  gist config.log
  exit 1
# should also upload subfolder config.log's, if I can get that to work
fi
make all -j4
make install
make test
