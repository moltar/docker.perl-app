#!/usr/bin/env sh

## create app user and group
groupadd -r $APP_USER -g 200 && \
useradd -u 200 -r -g $APP_USER -d $APP_DIR -s /sbin/nologin -c "$APP_USER user" $APP_USER && \
chown -R $APP_USER:$APP_USER $APP_DIR

PERL_VERSION_FILE=$APP_DIR/.perl-version
ENTRYPOINT=""

## read Perl version from the special .perl-version file that plenv understands
## otherwise assume the latest Perl version
if [ -f $PERL_VERSION_FILE ]; then
   PLENV_VERSION=$(cat $PERL_VERSION_FILE)
else
   PLENV_VERSION=$(plenv install --list | grep -v 'RC' | tail -n1 | tr -d ' ')
fi

## install Perl via plenv
## $PLENV_INSTALL variable is inherited from moltar/plenv image
$PLENV_INSTALL $PLENV_VERSION

## before_build hook
if [ -x $APP_DIR/before_build ]; then
    echo "Running $APP_DIR/before_build"
    cd $APP_DIR && ./before_build
fi

## if we have a Carton environment, then build using that
if [ -f $APP_DIR/cpanfile.snapshot ]; then
    ## remove already installed modules from local/ dir
    ## if it appears to be managed by carton
    if [ -d $APP_DIR/local/lib/perl5 ]; then
        rm -rf $APP_DIR/local
    fi

    ## if we have carton vendor cache, then use that
    ## and the script that comes with it
    if [ -d $APP_DIR/vendor/cache ]; then
        vendor/bin/carton install --deployment --cached
        ENTRYPOINT="vendor/bin/carton exec"
        rm -rf $APP_DIR/vendor/cache;
    else
        plenv exec cpanm --notest --quiet Carton && \
        plenv rehash && \
        plenv exec carton install --deployment
        ENTRYPOINT="plenv exec carton exec"
        rm -rf $APP_DIR/local/cache $APP_DIR/local/man
    fi
## otherwise try installing deps with cpanm, but do not fail in case
## there are no deps defined (e.g. not Makefile.PL, cpanfile or any other)
else
    plenv exec cpanm --installdeps . || true
    plenv rehash
    ENTRYPOINT="plenv exec"
fi

if [ -x $APP_DIR/after_build ]; then
    echo "Running $APP_DIR/after_build"
    cd $APP_DIR && ./after_build
fi

## clean up
cd $APP_DIR && rm -rf .git /root/.cpanm/

## create entrypoint script
echo "#!/usr/bin/env sh\nexec /sbin/my_init -- /sbin/setuser $APP_USER $ENTRYPOINT \"\$@\"" > /entrypoint.sh && \
chmod 755 /entrypoint.sh