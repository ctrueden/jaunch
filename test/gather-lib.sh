# Helper script to check out the latest version of an artifact
# and its dependencies to a ./lib directory
# Param 1: group ID
# Param 2: artifact ID

mkdir lib
mvn dependency:copy -Dartifact=$1:$2:LATEST -DoutputDirectory=lib >/dev/null
mvn dependency:copy -Dartifact=$1:$2:LATEST:pom -DoutputDirectory=. >/dev/null
mv $2*.pom pom.xml
mvn dependency:copy-dependencies -DoutputDirectory=lib  >/dev/null
rm pom.xml
