.PHONY: all test clean

all: test

clean:
	rm -rf build

test:
	ponyc --debug -o build test
	./build/test
