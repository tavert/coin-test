#!/bin/sh
# linux build

COIN_PROJECT=OS
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
# ruby is for this script that uploads logs anonymously to gist.github.com
sudo gem install gist

# download COIN source, will do an update if already downloaded
svn_broken=no
svn_cmds="-q --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$COIN_PROJECT/$PROJECT_VERSION $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION"
svn co $svn_cmds || svn_broken=yes
# svn incompatibility may require retrying a few times
if test $svn_broken = yes; then
# so much for the cache... hopefully this won't need to happen too often
  rm -rf $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION
  svn co $svn_cmds
fi
cd $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION
# do svn update in case of connectivity trouble during checkout (seems to only be a travis problem)
#svn update --non-interactive --trust-server-cert

# run autotools (old versions currently used)?
if test 1 = 1; then
  wget https://projects.coin-or.org/BuildTools/raw-attachment/ticket/105/dependencies_multipatch_config_option.patch
  patch -p0 < dependencies_multipatch_config_option.patch
  mkdir -p $WERCKER_CACHE_DIR/autotools_old
  wget https://projects.coin-or.org/BuildTools/raw-attachment/ticket/95/get_autotools.patch
  patch -p0 < get_autotools.patch
  cp autotools/get.autotools $WERCKER_CACHE_DIR/autotools_old
  cd $WERCKER_CACHE_DIR/autotools_old
  chmod +x get.autotools
  ./get.autotools
  export PATH=$WERCKER_CACHE_DIR/autotools_old/bin:$PATH
  export AUTOTOOLS_DIR=$WERCKER_CACHE_DIR/autotools_old
  cd $WERCKER_CACHE_DIR/$COIN_PROJECT/$PROJECT_VERSION
  BuildTools/run_autotools
fi

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
# uncomment one of the following cleanup lines if potential problems from past builds (config changes, etc)
#rm build/config.cache || true
#rm -rf build || true
mkdir -p build
cd build
do_gist=no
../configure -C LDFLAGS="-Wl,--no-undefined" --enable-dependency-linking || do_gist=yes
if test $do_gist = yes; then
  echo "CONFIG.LOG UPLOADED TO URL:"
  gist config.log
  exit 1
# should also upload subfolder config.log's, if I can get that to work
fi
make all -j4
make install
make test

# clang build, change next line to enable
if test 1 = 0; then
  # uncomment one of the following cleanup lines if potential problems from past builds (config changes, etc)
  #rm ../build_clang/config.cache || true
  #rm -rf ../build_clang || true
  mkdir -p ../build_clang
  cd ../build_clang
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
fi
