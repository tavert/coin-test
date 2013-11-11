#!/usr/bin/sh
# cygwin build

COIN_PROJECT=CoinUtils
PROJECT_VERSION=trunk

# install prerequisites using apt-cyg
svn export --force https://github.com/ashumkin/apt-cyg.git/trunk/apt-cyg /usr/local/bin/apt-cyg
chmod +x /usr/local/bin/apt-cyg
mkdir -p $WERCKER_CACHE_DIR/apt-cyg
apt-cyg -c $WERCKER_CACHE_DIR/apt-cyg install make gcc-g++ gcc-fortran
#apt-cyg install make mingw64-x86_64-gcc-g++ mingw64-x86_64-gcc-fortran

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
echo "" >> CoinUtils/src/CoinLpIO.hpp

# might need to build in the main source tree to avoid symlinking data files with mingw compilers
# uncomment one of the below cleanup lines if potential problems from past builds (config changes, etc)
#rm build/config.cache || true
#rm -rf build || true
mkdir -p build
cd build
../configure -C
#CYGPATH_W="cygpath -w" --host=x86_64-w64-mingw32
make all -j4
make install
make test



#echo $PATH
#cd $COIN_PROJECT/test
#make unitTest.exe
#ldd unitTest.exe
#cd ../..
