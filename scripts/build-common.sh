#!/bin/sh
#

. build-func.sh

init_debug() {
	echo -n ""
}


init_release() {
	echo -n ""
}

init_windows() {
	ZLIB_MAKEFILES="-f win32/Makefile.gcc"
}

init_linux() {
	if [ $DO_IMAGE_FORMATS -a $DO_IMAGE_FORMATS = "true" ] ; then
		postmessage "En GNU/Linux no se deben compilar bibliotecas de imagenes, se deben usar del sistema"
		unset DO_IMAGE_FORMATS
	fi
}

initialize $* || die

if [ $DO_IMAGE_FORMATS -a $DO_IMAGE_FORMATS = "true" ] ; then
	ZLIB_INSTALLFLAGS="SHARED_MODE=1 -e INCLUDE_PATH=$PREFIX/include -e LIBRARY_PATH=$PREFIX/lib -e BINARY_PATH=$PREFIX/bin"
	PNG_LIBS="-L$PREFIX/lib"
	PNG_FLAGS="-I$PREFIX/include"


	mkdir -p $PREFIX/lib
	mkdir -p $PREFIX/include
	mkdir -p $PREFIX/bin
	mkdir -p $PREFIX/share/sur

	rm -r -f zlib-1.2.8/
	build_library "${SRCDIR}/zlib-1.2.8.tar.gz" "no-configure" "$ZLIB_MAKEFILES" "$ZLIB_MAKEFILES $ZLIB_INSTALLFLAGS" -p "zlib_rename_dll.patch" "zlib-mingw.patch" || die

	mkdir -p $PREFIX/bin
	mkdir -p $PREFIX/man/man1
	cp "${SRCDIR}/jpegsrc.v8c.tar.gz" ./jpeg-8c.tar.gz || die
	build_library "./jpeg-8c.tar.gz" "$COMMON_FLAGS $SHARED $STATIC" "" "" || die
	rm ./jpeg-8c.tar.gz

	export LIBS=$PNG_LIBS
	export CPPFLAGS="$CPPFLAGS $PNG_FLAGS"
	build_library "${SRCDIR}/libpng-1.6.2.tar.gz" "$COMMON_FLAGS $SHARED $STATIC --disable-dependency-tracking" || die
	reset_flags

	build_library "${SRCDIR}/tiff-4.0.6.tar.gz" "$COMMON_FLAGS $SHARED $STATIC --disable-dependency-tracking --with-zlib-include-dir=$PREFIX/include --with-zlib-lib-dir=$PREFIX/lib --with-jpeg-include-dir=$PREFIX/include --with-jpeg-lib-dir=$PREFIX/lib" || die

	build_library "${SRCDIR}/expat-2.0.1.tar.gz" "$COMMON_FLAGS $SHARED $STATIC" "" "" || die
fi

reset_flags
export CFLAGS="-pipe"
export CXXFLAGS="-pipe"
build_library "${SRCDIR}/muparser_v2_2_2.tar.gz" "$COMMON_FLAGS --disable-samples" "" "" || die
reset_flags

#El script deja los binarios generados en la carpeta bin
move_packages
