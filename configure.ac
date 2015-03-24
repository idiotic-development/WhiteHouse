# configure.ac

AC_INIT(White House, 1.0)
AC_CONFIG_SRCDIR(src/Window.vala)

AM_INIT_AUTOMAKE

AC_PROG_CC
AC_PROG_CC_STDC
AM_PROG_VALAC([0.7.0])
AC_PROG_INSTALL

WHITE_HOUSE_PACKAGES="--pkg gio-2.0 --pkg gtk+-3.0 --pkg gee-0.8 --pkg json-glib-1.0"
PKG_CHECK_MODULES(WHITE_HOUSE, [glib-2.0 gio-2.0 gtk+-3.0 gee-0.8 json-glib-1.0])
AC_SUBST(WHITE_HOUSE_CFLAGS)
AC_SUBST(WHITE_HOUSE_LIBS)
AC_SUBST(WHITE_HOUSE_PACKAGES)

AC_CONFIG_FILES([
	Makefile
	resources/white-house.desktop
	resources/Makefile
	src/Makefile
])
AC_OUTPUT
