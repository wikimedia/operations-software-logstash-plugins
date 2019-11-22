all:
	LS_VERSION=7.4.0 ./build.sh
	LS_VERSION=6.8.5 ./build.sh

clean:
	rm -rf build

install:
	install -v -D --target-directory $(DESTDIR)/usr/share/logstash-plugins/ build/*.zip
