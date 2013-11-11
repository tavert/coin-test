#!/usr/bin/sh

COIN_PROJECT=CoinUtils
PROJECT_VERSION=trunk

# install prerequisites using apt-cyg
svn export https://github.com/kou1okada/apt-cyg.git/trunk/apt-cyg /usr/local/bin/apt-cyg
chmod +x /usr/local/bin/apt-cyg
apt-cyg -m http://mirrors.kernel.org/sourceware/cygwin/ install make gcc-g++ gcc-fortran
#apt-cyg install make mingw64-x86_64-gcc-g++ mingw64-x86_64-gcc-fortran

# download COIN source
svn co -q --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$COIN_PROJECT/$PROJECT_VERSION ~/$COIN_PROJECT/$PROJECT_VERSION
cd ~/$COIN_PROJECT/$PROJECT_VERSION
# do svn update in case of connectivity trouble during checkout
svn update --non-interactive --trust-server-cert

# download third-party source
for i in `ls ThirdParty/*/get.*`; do
  cd `dirname $i`
  ./`basename $i`
  cd ../..
done

# add a newline at end of CoinUtils/src/CoinLpIO.hpp until fixed
mkdir -p CoinUtils/src
echo "" >> CoinUtils/src/CoinLpIO.hpp

# build in the main source tree to avoid symlinking data files
mkdir build
cd build
../configure -C
#CYGPATH_W="cygpath -w" --host=x86_64-w64-mingw32
make all -j4
make install
#echo $PATH
#cd $COIN_PROJECT/test
#make unitTest.exe
#ldd unitTest.exe
#cd ../..
make test
