require 'formula'

# Nethack the way God intended it to be played: from a terminal.
# This build script was created referencing:
# * http://nethackwiki.com/wiki/Compiling#On_Mac_OS_X
# * http://nethackwiki.com/wiki/Pkgsrc#patch-ac_.28system.h.29
# and copious hacking until things compiled.
#
# The patch applied incorporates the patch-ac above, the OS X
# instructions from the Wiki, and whatever else needed to be
# done.
# - @adamv

class Nethack < Formula
  homepage 'http://www.nethack.org/index.html'
  url 'http://downloads.sourceforge.net/project/nethack/nethack/3.4.3/nethack-343-src.tgz'
  version '3.4.3'
  md5 '21479c95990eefe7650df582426457f9'

  fails_with_llvm :build => 2334

  # Don't remove save folder
  skip_clean 'libexec/save'

  def patches
    ['http://alt.org/nethack/nh343-nao.diff', DATA]
  end

  def install
    # Build everything in-order; no multi builds.
    ENV.deparallelize

    # Symlink makefiles
    system 'sh sys/unix/setup.sh'

    inreplace "include/config.h" do |s|
      s.gsub! /^#\s*define HACKDIR.*$/, "#define HACKDIR \"#{libexec}\""
      s.gsub! /^#\s*define COMPRESS\s.*$/, "#define COMPRESS \"/usr/bin/gzip\""
    end

    inreplace "include/unixconf.h",
      /^#\s*define VAR_PLAYGROUND.*$/,
      "#define VAR_PLAYGROUND \"#{libexec}\""

    # Make the data first, before we munge the CFLAGS
    system "cd dat;make"

    cd 'dat' do
      %w(perm logfile xlogfile livelog).each do |f|
        system "touch", f
        libexec.install f
      end

      # Stage the data
      libexec.install %w(help hh cmdhelp history opthelp wizhelp dungeon license data oracles options rumors quest.dat)
      libexec.install Dir['*.lev']
    end

    # Make the game
    ENV.append_to_cflags "-I../include"
    system 'cd src;make'

    bin.install 'src/nethack'
    (libexec+'save').mkpath

    # These need to be group-writable in multi-user situations
    system "chmod", "g+w", libexec
    system "chmod", "g+w", libexec+'save'
  end
end

__END__
diff --git a/include/config.h b/include/config.h
index 9f653d3..2d2fc83 100644
--- a/include/config.h
+++ b/include/config.h
@@ -380,8 +380,8 @@ typedef unsigned char	uchar;
 #define AUTOPICKUP_EXCEPTIONS  /* exceptions to autopickup */
 
 #define DUMP_LOG        /* Dump game end information to a file */
-#define DUMP_FN "/dgldir/userdata/%N/%n/dumplog/%t.nh343.txt"      /* Fixed dumpfile name, if you want
-                                   * to prevent definition by users */
+/* #define DUMP_FN "/dgldir/userdata/%N/%n/dumplog/%t.nh343.txt"      /1* Fixed dumpfile name, if you want */
+                                   /* * to prevent definition by users *1/ */
 #define DUMPMSGS 20     /* Number of latest messages in the dump file  */
 
 #define SHOW_BORN    /* extinct & showborn -patch */
diff --git a/include/system.h b/include/system.h
index a4efff9..cfe96f1 100644
--- a/include/system.h
+++ b/include/system.h
@@ -79,10 +79,10 @@ typedef long	off_t;
 # if !defined(__SC__) && !defined(LINUX)
 E  long NDECL(random);
 # endif
-# if (!defined(SUNOS4) && !defined(bsdi) && !defined(__FreeBSD__)) || defined(RANDOM)
+# if (!defined(SUNOS4) && !defined(bsdi) && !defined(__NetBSD__) && !defined(__FreeBSD__) && !defined(__DragonFly__) && !defined(__APPLE__)) || defined(RANDOM)
 E void FDECL(srandom, (unsigned int));
 # else
-#  if !defined(bsdi) && !defined(__FreeBSD__)
+#  if !defined(bsdi) && !defined(__NetBSD__) && !defined(__FreeBSD__) && !defined(__DragonFly__) && !defined(__APPLE__)
 E int FDECL(srandom, (unsigned int));
 #  endif
 # endif
@@ -132,7 +132,7 @@ E void FDECL(perror, (const char *));
 E void FDECL(qsort, (genericptr_t,size_t,size_t,
 		     int(*)(const genericptr,const genericptr)));
 #else
-# if defined(BSD) || defined(ULTRIX)
+# if defined(BSD) || defined(ULTRIX) && !defined(__NetBSD__)
 E  int qsort();
 # else
 #  if !defined(LATTICE) && !defined(AZTEC_50)
@@ -421,7 +421,7 @@ E size_t FDECL(strlen, (const char *));
 # ifdef HPUX
 E unsigned int	FDECL(strlen, (char *));
 #  else
-#   if !(defined(ULTRIX_PROTO) && defined(__GNUC__))
+#   if !(defined(ULTRIX_PROTO) && defined(__GNUC__)) && !defined(__NetBSD__)
 E int	FDECL(strlen, (const char *));
 #   endif
 #  endif /* HPUX */
@@ -476,9 +476,9 @@ E  char *sprintf();
 #  if !defined(SVR4) && !defined(apollo)
 #   if !(defined(ULTRIX_PROTO) && defined(__GNUC__))
 #    if !(defined(SUNOS4) && defined(__STDC__)) /* Solaris unbundled cc (acc) */
-E int FDECL(vsprintf, (char *, const char *, va_list));
-E int FDECL(vfprintf, (FILE *, const char *, va_list));
-E int FDECL(vprintf, (const char *, va_list));
+// E int FDECL(vsprintf, (char *, const char *, va_list));
+// E int FDECL(vfprintf, (FILE *, const char *, va_list));
+// E int FDECL(vprintf, (const char *, va_list));
 #    endif
 #   endif
 #  endif
@@ -521,7 +521,7 @@ E struct tm *FDECL(localtime, (const time_t *));
 #  endif
 # endif
 
-# if defined(ULTRIX) || (defined(BSD) && defined(POSIX_TYPES)) || defined(SYSV) || defined(MICRO) || defined(VMS) || defined(MAC) || (defined(HPUX) && defined(_POSIX_SOURCE))
+# if defined(ULTRIX) || (defined(BSD) && defined(POSIX_TYPES)) || defined(SYSV) || defined(MICRO) || defined(VMS) || defined(MAC) || (defined(HPUX) && defined(_POSIX_SOURCE)) || defined(__NetBSD__)
 E time_t FDECL(time, (time_t *));
 # else
 E long FDECL(time, (time_t *));
diff --git a/include/unixconf.h b/include/unixconf.h
index f7cdcf7..d39d329 100644
--- a/include/unixconf.h
+++ b/include/unixconf.h
@@ -19,13 +19,13 @@
  */
 
 /* define exactly one of the following four choices */
-/* #define BSD 1 */	/* define for 4.n/Free/Open/Net BSD  */
+#define BSD 1 	/* define for 4.n/Free/Open/Net BSD  */
 			/* also for relatives like SunOS 4.x, DG/UX, and */
 			/* older versions of Linux */
 /* #define ULTRIX */	/* define for Ultrix v3.0 or higher (but not lower) */
 			/* Use BSD for < v3.0 */
 			/* "ULTRIX" not to be confused with "ultrix" */
-#define SYSV		/* define for System V, Solaris 2.x, newer versions */
+/* #define SYSV */		/* define for System V, Solaris 2.x, newer versions */
 			/* of Linux */
 /* #define HPUX */	/* Hewlett-Packard's Unix, version 6.5 or higher */
 			/* use SYSV for < v6.5 */
@@ -291,8 +291,8 @@
 
 #if defined(BSD) || defined(ULTRIX)
 # if !defined(DGUX) && !defined(SUNOS4)
-#define memcpy(d, s, n)		bcopy(s, d, n)
-#define memcmp(s1, s2, n)	bcmp(s2, s1, n)
+// #define memcpy(d, s, n)      bcopy(s, d, n)
+// #define memcmp(s1, s2, n)    bcmp(s2, s1, n)
 # endif
 # ifdef SUNOS4
 #include <memory.h>
diff --git a/sys/unix/Makefile.src b/sys/unix/Makefile.src
index ab56b76..9fc82bd 100644
--- a/sys/unix/Makefile.src
+++ b/sys/unix/Makefile.src
@@ -151,8 +151,8 @@ GNOMEINC=-I/usr/lib/glib/include -I/usr/lib/gnome-libs/include -I../win/gnome
 # flags for debugging:
 # CFLAGS = -g -I../include
 
-CFLAGS = -g -O -I../include
-LFLAGS =
+#CFLAGS = -O -I../include
+#LFLAGS =
 
 # The Qt and Be window systems are written in C++, while the rest of
 # NetHack is standard C.  If using Qt, uncomment the LINK line here to get
@@ -293,7 +293,7 @@ WINLIB = $(WINTTYLIB)
 LIBS =
 
 # make NetHack
-GAME     = nethack.343-nao
+GAME     = nethack
 # GAME     = nethack.prg
 
 # if you defined RANDOM in unixconf.h/tosconf.h since your system did not come
diff --git a/win/tty/termcap.c b/win/tty/termcap.c
index a65a1d1..31b36c8 100644
--- a/win/tty/termcap.c
+++ b/win/tty/termcap.c
@@ -836,7 +836,7 @@ cl_eos()			/* free after Robert Viduya */
 
 #include <curses.h>
 
-#ifndef LINUX
+#if !defined(LINUX) && !defined(__APPLE__)
 extern char *tparm();
 #endif
 
