# Koel on Railway: the official image, pinned by version and digest.
# Upstream: https://github.com/koel/docker (image phanan/koel on Docker Hub)
FROM phanan/koel:9.15.0@sha256:af1ec7daf06d22f6781d9e79716e52048108c21b05adfebccec2e474a29f6fde

# Music lives on the Railway volume (/data/music), so let Apache's X-Sendfile serve it from there too.
RUN sed -i 's#^\(\s*\)XSendFilePath /music#&\n\1XSendFilePath /data/music#' /etc/apache2/sites-available/000-default.conf \
  && grep -q 'XSendFilePath /data/music' /etc/apache2/sites-available/000-default.conf

COPY railway-start.sh /usr/local/bin/railway-start.sh
COPY railway-admin.php /usr/local/bin/railway-admin.php
RUN chmod 755 /usr/local/bin/railway-start.sh

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD ["apache2-foreground"]
