.PHONY: all
all: hello_c hello_lib.so

hello_c: ./hello.c
	gcc -o $@ $?

hello_lib.so: ./hello.c
	gcc -g -shared -o $@ $?
