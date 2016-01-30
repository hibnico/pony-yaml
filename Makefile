.PHONY: all test clean

all: test

clean:
	rm -rf build

test:
	ponyc -p src --debug -o build src/async_parser_tests
	./build/async_parser_tests
