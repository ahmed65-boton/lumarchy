.DEFAULT_GOAL := help

.PHONY: help check build aur iso clean

help:
	@printf '%s\n' \
	  'make check  - run static project checks' \
	  'make build  - build AUR packages and ze Lumarchy ISO' \
	  'make aur    - rebuild only ze local AUR repository' \
	  'make iso    - build ISO using an existing local repository' \
	  'make clean  - remove transient build state (keeps output)'

check:
	./lumarchy-build.sh check

build:
	sudo ./lumarchy-build.sh all

aur:
	sudo ./lumarchy-build.sh aur

iso:
	sudo ./lumarchy-build.sh iso

clean:
	sudo ./lumarchy-build.sh clean
