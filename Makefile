lib/%.js: lib/%.coffee
	cat "$<" | ./node_modules/.bin/coffee -b -c -s | ./node_modules/.bin/standard-format - > "$@"

all: $(patsubst lib/%.coffee, lib/%.js, $(wildcard lib/*.coffee))

clean:
	rm lib/*.js
