# *** manually set environments (for intel compiler) of ip2 ***

# !!! module environment (*THEIA*) !!!
 module load intel/18.1.163
#module load ics/17.0.3

 ANCHORDIR=..
 export COMP=ips
 export IP2_VER=v1.0.0
 export IP2_SRC=
 export IP2_INC4=$ANCHORDIR/include/ip2_${IP2_VER}_4
 export IP2_INC8=$ANCHORDIR/include/ip2_${IP2_VER}_8
 export IP2_INCd=$ANCHORDIR/include/ip2_${IP2_VER}_d
 export IP2_LIB4=$ANCHORDIR/libip2_${IP2_VER}_4.a
 export IP2_LIB8=$ANCHORDIR/libip2_${IP2_VER}_8.a
 export IP2_LIBd=$ANCHORDIR/libip2_${IP2_VER}_d.a

 export CC=icc
 export FC=ifort
 export CPP=cpp
 export OMPCC="$CC -qopenmp"
 export OMPFC="$FC -qopenmp"
 export MPICC=mpiicc
 export MPIFC=mpiifort

 export DEBUG="-g -O0"
 export CFLAGS="-O3 -fPIC"
 export FFLAGS="-O3 -fp-model strict -ip -convert little_endian -assume byterecl -fPIC"
 export FPPCPP="-cpp"
 export FREEFORM="-free"
 export CPPFLAGS="-P -traditional-cpp"
 export MPICFLAGS="-O3 -fPIC"
 export MPIFFLAGS="-O3 -fPIC"
 export MODPATH="-module "
 export I4R4="-integer-size 32 -real-size 32"
 export I4R8="-integer-size 32 -real-size 64"
 export I8R8="-integer-size 64 -real-size 64"

 export CPPDEFS=""
 export CFLAGSDEFS="-DUNDERSCORE -DLINUX"
 export FFLAGSDEFS=""

 export USECC=""
 export USEFC="YES"
 export DEPS=""
