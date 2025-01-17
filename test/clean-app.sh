rm -rf .jaunch

if [ $# -gt 0 ]; then
	rm -f $1
	rm -f $1.log
fi
