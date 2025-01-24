# Helper script to clean up a constructed app
# Param 1: app name (optional)

rm -rf .jaunch

if [ $# -gt 0 ]; then
	rm -f $1
	rm -f $1.log
fi
