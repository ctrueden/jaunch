# Helper script to set up the files for an app
# Copies .toml files to a local .jaunch dir and makes
# an app launcher
# Param 1: name of the app to make (optional)

mkdir .jaunch
cp -r ../configs/* .jaunch/
cp bin/linuxX64/releaseExecutable/jaunch.kexe ./jaunch-linux-x64

if [ $# -gt 0 ]; then
	cp launcher-linux-x64 $1
fi
