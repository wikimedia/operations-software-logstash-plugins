PLUGINS := logstash-filter-logfmt logstash-output-loki logstash-output-opensearch

all:
	install -d ./build
	/usr/share/logstash/bin/logstash-plugin install $(PLUGINS)
	/usr/share/logstash/bin/logstash-plugin prepare-offline-pack --output ./build/logstash-plugins.zip $(PLUGINS)

clean:
	rm -rf build

install:
	install -v -D --target-directory $(DESTDIR)/usr/share/logstash-plugins/ build/*.zip

