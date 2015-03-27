# Makefile.am

SUBDIRS = resources src
EXTRA_DIST = autogen.sh com.idioticdev.whitehouse.gschema.xml

gsettings_SCHEMAS = com.idioticdev.whitehouse.gschema.xml
@GSETTINGS_RULES@

pkg-deb:dist
		tar -xzf $(PACKAGE)-$(VERSION).tar.gz &&\
		mv $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)_$(VERSION).orig.tar.gz &&\
		cd $(PACKAGE)-$(VERSION) &&\
		dh_make -e _c_@mail.com -c gpl3 --single -y &&\
		cp ../pkg/deb/* debian/ &&\
		dpkg-buildpackage -rfakeroot -us -uc -b &&\
		cd .. &&\
		rm -rf $(PACKAGE)-$(VERSION) $(PACKAGE)_$(VERSION).orig.tar.gz
.PHONY: pkg-deb