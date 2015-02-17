rubygem_miner
=============

This script  will look for basic vulnerabilities in ruby gems, it scrapes rubygems.org for all gems that begin with letter $argument.

So $> ./vuln_scrape.sh A

The above command will download all ruby gems that start with the letter A and look for simple vulnerabilities.  There are false positives but in a sea of code, you'll get a lake of possible vulnerabilities to look at.

Also there is much room for improvement, this should really be re-written to use the rubygems.org API.

And please don't pound the living shit out of rubygems.org.  I would try to run this off hours and I would often put
a sleep 1 in the for loops.
