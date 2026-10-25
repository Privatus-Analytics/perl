# Conformance example app (Mojolicious). Build with the package folder as the
# context:  docker build -f example/Dockerfile .
FROM perl:5.40-slim
WORKDIR /app
RUN cpanm -nq Mojolicious && rm -rf /root/.cpanm
# The package from this repo's own source, not from CPAN.
COPY Makefile.PL cpanfile README.md LICENSE CHANGELOG.md MANIFEST /pkg/
COPY lib/ /pkg/lib/
RUN cpanm -nq --notest /pkg && rm -rf /root/.cpanm
COPY example/ .
EXPOSE 8080
CMD ["sh", "-c", "exec perl app.pl prefork -m production -l http://0.0.0.0:${PORT:-8080} -w 4 -c 100"]
