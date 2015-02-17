#!/bin/sh
#ruby gem scraper, grab all the gems to hAck
#Larry Cashdollar, @_larry0 2/17/2015

echo "[+] Scraping rubygems.org for all $1 Gems";
echo "[+] Cleaning up files";

WPATH=workdir
OUTPATH=outdir

rm -rf working.$1
echo "[+] Getting number of pages for letter $1";

wget https://rubygems.org/gems?letter=$1 -O $1.max

NUM=`cat $1.max | grep Next | awk -F\= '{print $36}' | awk -F\" '{print $1}'`

#will give us number of pages in Cx
echo "[+] Number of pages :"$NUM

echo "[+] Downloading all $1 gems"

for x in `seq 1 $NUM`; do wget  -nv https://rubygems.org/gems?letter=$1\&page=$x -O $1.$x.list ; done

echo "[+] Creating package list"

cat $1.*.list  |grep "href=\"/gems/"  | awk -F= '{print $3}' | sed -e 's/\/gems\///g' | sed -e 's/\"//g' | sed -e 's/>//' > main_pkg_list.$1
echo "[+] Downloading all packages pages for parsing"

mkdir working.$1

for x in `cat main_pkg_list.$1`; do wget -nv https://rubygems.org/gems/$x -O working.$1/$x ; done

cd working.$1

LIST=`ls|wc -l`

echo "[+] Creating download script for $LIST gems."
echo "#!/bin/sh" > download.sh.tmp

for x in `ls`; do cat $x |grep Download | awk -F\" '{print "wget -nv https://rubygems.org"$4}'; done >> download.sh.tmp
cat download.sh.tmp | sort -u > download.sh
mkdir data.$1
mv download.sh data.$1
cd data.$1
chmod 755 download.sh
echo "[+] Downloading gems.."
./download.sh
echo "[+] Renaming files from .gem to .tar"

for x in `ls|grep gem`; do echo -n "mv $x "; echo "$x" | sed -e 's/.gem/.tar/'; done  > rename

sh rename
rm rename
echo "[+] Unpacking"
for x in `ls *.tar`; do echo $x | sed -e 's/.tar//'| xargs  mkdir ; done

for x in `ls |grep -v .tar` ; do echo "- Working on $x";tar -xmf $x.tar -C $x ; done

for x in `ls|grep -v .tar`; do echo "- Unpacking $x"; tar -zxmf $x/data.tar.gz -C $x; done

echo "[+] Generating file lists of potential targets"

cd $WPATH/working.$1/data.$1
echo  "************************************************************"
pwd
echo  "************************************************************"

find . -name *.rb -exec grep -l "\`#{command}\`" {} \; > cmdfile.$1.log   
find . -name *.rb -exec egrep -l "api_key|apikey" {} \; > api_key.$1.log   
find . -name *.rb -exec egrep -l "\`*\`" {} \; > backtick.$1.log
find . -name *.rb -exec egrep -l "system\(|system\s\(" {} \; > system.$1.log
find . -name *.rb -exec egrep -l '%x[\{\(\[]' {} \; > x_percent.$1.log   
find . -name *.rb -exec grep -l "/tmp" {} \; > tmpfile.$1.log

echo "[+] Looking for (basic) command exec vulnerabilities."
#we are only finding a few of them, see http://tech.natemurray.com/2007/03/ruby-shell-commands.html
for x in `cat cmdfile.$1.log`; do echo "+--------------------[$x]-------------------+"; grep -nC3  "\`#{command}\`" $x; echo "+---------------------------------------------------------------------+"; done > command.$1.log.txt

for x in `cat x_percent.$1.log`; do echo "+--------------------[$x]-------------------+"; egrep -nC3  '%x[\{\(\[]' $x; echo "+---------------------------------------------------------------------+"; done > x_percent.$1.log.txt

for x in `cat backtick.$1.log`; do echo "+--------------------[$x]-------------------+"; egrep -nC3 "\`*\`" $x; echo "+---------------------------------------------------------------------+"; done > backtick.$1.log.txt

for x in `cat system.$1.log`; do echo "+--------------------[$x]-------------------+"; egrep -nC3 "system\(|system\s\(" $x; echo "+---------------------------------------------------------------------+"; done > system.$1.log.txt

echo "[+] Looking for /tmp file vulnerabilities."

for x in `cat tmpfile.$1.log`; do echo "+--------------------[$x]-------------------+"; grep -nC3  "/tmp" $x; echo "+---------------------------------------------------------------------+"; done > tmpfile.$1.log.txt

echo "[+] Looking for API key exposure vulnerabilities."

for x in `cat api_key.$1.log`; do echo "+--------------------[$x]-------------------+"; egrep -nC3  "api_key|apikey" $x; echo "+---------------------------------------------------------------------+"; done > api_key.$1.log.txt

#echo "[+] Generating HTML reports"

#cat command.$1.log.txt | txt2html > /var/www/$1-cmdexec.html
#cat tmpfile.$1.log.txt | txt2html > /var/www/$1-tmpfile.html
#cat x_percent.$1.log.txt | txt2html > /var/www/$1-x_percent.html
#cat api_key.$1.log.txt | txt2html > /var/www/$1-api_key.html
#cat backtick.$1.log.txt | txt2html > /var/www/$1-backtick.html
#cat system.$1.log.txt | txt2html > /var/www/$1-system.html

cp command.$1.log.txt   $OUTPATH/$1-command.txt
cp tmpfile.$1.log.txt   $OUTPATH/$1-tmpfile.txt
cp x_percent.$1.log.txt   $OUTPATH/$1-xexec.txt
cp api_key.$1.log.txt   $OUTPATH/$1-apikey.txt
cp backtick.$1.log.txt  $OUTPATH/$1-backtick.txt
cp system.$1.log.txt   $OUTPATH/$1-system.txt

cd $WPATH

echo "[+] Done"
