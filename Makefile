.PHONY: all test clean

all: test

clean:
	rm -rf build

test:
	ponyc -p src --debug -o build src/async_parser_test
	./build/async_parser_test
