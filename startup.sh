#!/bin/sh


R CMD /usr/lib64/R/library/Rserve/libs/Rserve
/opt/glassfish/glassfish4/bin/asadmin start-domain --verbose=true
