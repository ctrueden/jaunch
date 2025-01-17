mkdir .jaunch
cp -r ../configs/* .jaunch/
cp bin/linuxX64/releaseExecutable/jaunch.kexe ./jaunch-linux-x64

if [ $# -gt 0 ]; then
	cp launcher-linux-x64 $1
fi
