.PHONY: all test clean

all: test

clean:
	rm -rf build

test:
	ponyc -o build test
	./build/test
