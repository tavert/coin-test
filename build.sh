#!/usr/bin/sh

# stop on error
set -e

COIN_PROJECT=CoinUtils/trunk

# install prerequisites using apt-cyg
svn export https://github.com/GiannisRambo/apt-cyg.git/trunk/apt-cyg apt-cyg
chmod +x apt-cyg
./apt-cyg install gcc-fortran

# download COIN source
svn co -q --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$COIN_PROJECT ~/$COIN_PROJECT
cd ~/$COIN_PROJECT
# do svn update in case of connectivity trouble during checkout
svn update --non-interactive --trust-server-cert

# download third-party source
for i in `ls ThirdParty/*/get.*`; do
  cd `dirname $i`
  ./`basename $i`
  cd ../..
done

# add a newline at end of CoinUtils/src/CoinLpIO.hpp until fixed
#echo "" >> CoinUtils/src/CoinLpIO.hpp

mkdir build
cd build
../configure -C
make all -j4
make install
make test

#    - curl -Sso wrap.rb https://gist.github.com/roidrage/5238585/raw
#    - chmod +x wrap.rb && ./wrap.rb "make all -j4 > make.log 2>&1"
#    - echo "CONFIGURE AND MAKE LOGS UPLOADED TO URL" && gist config.log make.log
# should upload more of the subdirectory config.log's too once that works
#    - make install && make test
