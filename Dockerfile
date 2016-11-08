FROM mjmg/fedora-r-base:latest

#install additional tools and library prerequisites
RUN \
  dnf install -y netcdf-devel libxml2-devel ImageMagick graphviz cairo-devel libXt-devel NLopt-devel

# Install Metaboanalyst R package prerequisites "Rserve", "ellipse", "scatterplot3d","pls", "caret", "multicore", "lattice", "Cairo", 
# "randomForest", "e1071","gplots", "som", "xtable", "RColorBrewer", "xcms","impute", "pcaMethods","siggenes", 
# "globaltest", "GlobalAncova", "Rgraphviz","KEGGgraph", "preprocessCore", "genefilter", "pheatmap", "igraph", 
# "RJSONIO", "SSPA", "caTools", "ROCR", "pROC" 
# Parallel package is used instead of multicore which is already in core packages

# This installs other R packages under Bioconductor
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('mzR')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('xcms')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('globaltest')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('impute')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('pcaMethods')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('siggenes')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('globaltest')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('Rgraphviz')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('KEGGgraph')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('preprocessCore')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('genefilter')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('SSPA')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('GlobalAncova')"

# This installs other R packages from CRAN
RUN Rscript -e "install.packages('Rserve')"
RUN Rscript -e "install.packages('ellipse')"
RUN Rscript -e "install.packages('scatterplot3d')"
RUN Rscript -e "install.packages('pls')"
RUN Rscript -e "install.packages('caret')"
RUN Rscript -e "install.packages('lattice')"
RUN Rscript -e "install.packages('Cairo')"
RUN Rscript -e "install.packages('randomForest')"
RUN Rscript -e "install.packages('e1071')"
RUN Rscript -e "install.packages('gplots')"
RUN Rscript -e "install.packages('som')"
RUN Rscript -e "install.packages('xtable')"
RUN Rscript -e "install.packages('RColorBrewer')"
RUN Rscript -e "install.packages('pheatmap')"
RUN Rscript -e "install.packages('igraph')"
RUN Rscript -e "install.packages('RJSONIO')"
RUN Rscript -e "install.packages('caTools')"
RUN Rscript -e "install.packages('ROCR')"
RUN Rscript -e "install.packages('pROC')"


# Install and setup glassfish environment
# Based from https://github.com/glassfish/docker/blob/master/oracle-jdk/Dockerfile

ENV JAVA_HOME /usr/lib/jvm/java-openjdk
ENV GLASSFISH_PKG http://download.java.net/glassfish/4.0/release/glassfish-4.0.zip
ENV PKG_FILE_NAME glassfish-4.0.zip

#From https://github.com/glassfish/docker/blob/master/oracle-jdk/Dockerfile
RUN \  
  useradd -b /opt -m -s /bin/bash glassfish && echo glassfish:glassfish | chpasswd
RUN \
  cd /opt/glassfish && curl -O $GLASSFISH_PKG && unzip $PKG_FILE_NAME && rm $PKG_FILE_NAME

# Get webapp
RUN \
  cd /opt/glassfish && curl -O https://dl.dropboxusercontent.com/u/95163184/MetaboAnalyst.war
  
  
RUN \
  chown -R glassfish:glassfish /opt/glassfish* 
  
# Default glassfish ports
EXPOSE 4848 8009 8080 8181

# Set glassfish user in its home/bin by default
USER glassfish
WORKDIR /opt/glassfish/glassfish4/bin

# User: admin / Pass: glassfish
RUN echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > /opt/glassfish/glassfish4/glassfish/domains/domain1/config/admin-keyfile
RUN echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile
  
# Default to admin/glassfish as user/pass
RUN \
  ./asadmin start-domain && \
  ./asadmin --user admin --passwordfile pwdfile deploy  /opt/glassfish/MetaboAnalyst.war && \
  ./asadmin --user admin --passwordfile pwdfile enable-secure-admin && \
  ./asadmin stop-domain

RUN echo "export PATH=$PATH:/opt/glassfish/glassfish4/bin" >> /opt/glassfish/.bashrc

#COPY startup.sh /opt/glassfish/glassfish4/bin/startup.sh

USER root
# Add supervisor conf files
ADD \
  Rserve.conf /etc/supervisor/conf.d/Rserve.conf
ADD \
  glassfish.conf /etc/supervisor/conf.d/glassfish.conf

  
# Define default command.
CMD ["/usr/bin/supervisord","-c","/etc/supervisor.conf"]


#RUN chown -R glassfish:glassfish /opt/glassfish/glassfish4/bin/startup.sh && \
#    chmod +x /opt/glassfish/glassfish4/bin/startup.sh 

# Default command to run on container boot
#ENTRYPOINT ["/opt/glassfish/glassfish4/bin/startup.sh"]
