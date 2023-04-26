FROM fedora:37

RUN groupadd staff \
  && useradd -g staff -d /home/docker docker

LABEL org.label-schema.license="GPL-3.0" \
      org.label-schema.vcs-url="https://github.com/XiangyunHuang/data-analysis-in-action" \
      org.label-schema.vendor="Book Project" \
      maintainer="Xiangyun Huang <xiangyunfaith@outlook.com>"

ARG QUARTO_VERSION=1.2.280
ARG GITHUB_PAT=abc123

# System dependencies required for R packages
RUN dnf -y upgrade \
  && echo "install_weak_deps=False" >> /etc/dnf/dnf.conf \
  && dnf -y install dnf-plugins-core \
  && dnf -y install glibc-langpack-en \
   R-devel \
   R-littler \
   R-littler-examples \
   ghostscript \
   optipng \
   ImageMagick \
   texinfo \
   cargo \
   bzip2 \
   passwd \
   initscripts \
   firewalld \
 # Setup password use passwd
 && echo 'docker:docker123' | chpasswd \
 && dnf clean all
   
# System dependencies required for Quarto Book project
RUN dnf -y install python3-virtualenv \
   google-noto-cjk-fonts \
   google-noto-sans-fonts \
   google-noto-serif-fonts \
   google-noto-emoji-fonts \
   google-noto-emoji-color-fonts \
   texlive-sourceserifpro \
   texlive-sourcecodepro \
   texlive-sourcesanspro \
   texlive-pdfcrop \
   texlive-dvisvgm \
   texlive-dvips \
   texlive-dvipng \
   texlive-ctex \
   texlive-fandol \
   texlive-xetex \
   texlive-framed \
   texlive-titling \
   texlive-fira \
   texlive-awesomebox \
   texlive-fontawesome5 \
   texlive-fontawesome \
   texlive-newtx \
   texlive-tcolorbox \
   texlive-standalone \
   texlive-animate \
   texlive-media9 \
   chromium \
 && dnf clean all

# Setup R and RStudio Server Open Source
RUN ln -s /usr/lib64/R/library/littler/examples/install.r /usr/bin/install.r \
 && ln -s /usr/lib64/R/library/littler/examples/install2.r /usr/bin/install2.r \
 && ln -s /usr/lib64/R/library/littler/examples/installGithub.r /usr/bin/installGithub.r \
 && ln -s /usr/lib64/R/library/littler/examples/testInstalled.r /usr/bin/testInstalled.r \
 && mkdir -p /usr/local/lib/R/site-library \
 # Set group authority
 && chown -R docker:staff /usr/local/lib/R/site-library \
 && echo "options(repos = c(CRAN = 'https://cran.r-project.org/'))" | tee -a /usr/lib64/R/etc/Rprofile.site \
 && chmod a+r /usr/lib64/R/etc/Rprofile.site \
 && echo "LANG=en_US.UTF-8" >> /usr/lib64/R/etc/Renviron.site \
 && echo "export LC_ALL=en_US.UTF-8"  >> /etc/profile \
 && echo "export LANG=en_US.UTF-8"  >> /etc/profile \
 && echo "CXXFLAGS += -Wno-ignored-attributes" >> /usr/lib64/R/etc/Makeconf \
 && Rscript -e 'x <- file.path(R.home("doc"), "html"); if (!file.exists(x)) {dir.create(x, recursive=TRUE); file.copy(system.file("html/R.css", package="stats"), x)}' \
 && install.r docopt \
 && install2.r remotes \
 && dnf -y install rstudio-server \
 && cp /usr/lib/systemd/system/rstudio-server.service /etc/init.d/ \
 && chmod +x /etc/init.d/rstudio-server.service \
 && systemctl enable rstudio-server \
 && dnf clean all

# Set Extra R Packages
COPY DESCRIPTION DESCRIPTION
COPY desc_pkgs.txt desc_pkgs.txt
RUN dnf -y copr enable iucar/cran \
  && dnf -y install R-CoprManager \
  && dnf -y install $(cat desc_pkgs.txt) \
  && dnf clean all \
  && install2.r showtextdb showtext \
  && export GITHUB_PAT=${GITHUB_PAT} \
  && export DOWNLOAD_STATIC_LIBV8=1 \
  && Rscript -e "remotes::install_deps('.', dependencies = TRUE)" \
  && rm -f DESCRIPTION desc_pkgs.txt

# Set Quarto and Pandoc
RUN curl -fLo quarto.tar.gz https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz \
 && mkdir -p /opt/quarto/ \
 && tar -xzf quarto.tar.gz -C /opt/quarto/ \
 && ln -s /opt/quarto/quarto-${QUARTO_VERSION}/bin/quarto /usr/bin/quarto \
 && mv -f /usr/bin/pandoc /usr/bin/pandoc.bak \
 && ln -s /opt/quarto/quarto-${QUARTO_VERSION}/bin/tools/pandoc /usr/bin/pandoc \
 && rm -f quarto.tar.gz

# Set locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Set default timezone
ENV TZ=UTC

WORKDIR /home/docker/

EXPOSE 8787/tcp

CMD [ "/sbin/init" ]
