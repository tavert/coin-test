#!/usr/bin/sh

COIN_PROJECT=CoinUtils/trunk

# install prerequisites using apt-cyg
svn export https://github.com/zship/apt-cyg.git/trunk/apt-cyg apt-cyg
chmod +x apt-cyg
./apt-cyg install make mingw64-x86_64-gcc-g++ mingw64-x86_64-gcc-fortran

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
if test -f CoinUtils/src/CoinLpIO.hpp; then
  echo "" >> CoinUtils/src/CoinLpIO.hpp
fi

# build in the main source tree to avoid symlinking data files
./configure -C --host=x86_64-w64-mingw32
make all -j4
make install
make test
