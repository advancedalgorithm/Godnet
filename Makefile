.PHONY: new dependencies build clean

new:
	sudo apt update -y && apt upgrade -y
	sudo apt install git make gcc -y 
	cd ~/
	git clone https://github.com/vlang/v.git 
	cd v; make
	./v symlink

dependencies:
	@echo No Dependencies yet

build:
	cd ~/cnc
	v cnc.v
	@echo Godnet successfully build!
	