#!/bin/sh
# Runs the tests, Perl::Critic, perltidy and the CPAN tarball build in the
# official Perl image. Usage: ./run-docker.sh
# Modules are installed into ./local (git ignored) so later runs are fast.
set -e
docker run --rm -v "$PWD":/app -w /app perl:5.40 sh -c 'set -e
  export PERL5LIB=/app/local/lib/perl5 PATH=/app/local/bin:$PATH
  cpanm -nq -L local --installdeps --with-develop . >/dev/null
  perl Makefile.PL >/dev/null
  make >/dev/null
  make test
  perlcritic lib
  for f in $(find lib t -name "*.pm" -o -name "*.t") Makefile.PL; do
    perltidy --profile=.perltidyrc -st "$f" | diff -q - "$f" >/dev/null || { echo "perltidy: $f is not tidy"; exit 1; }
  done
  echo "perltidy: all files tidy"
  make dist >/dev/null
  ls PrivatusAnalytics-*.tar.gz
  make distclean >/dev/null
  rm -f PrivatusAnalytics-*.tar.gz
'
