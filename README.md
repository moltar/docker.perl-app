## Docker image for Perl projects ##

This is an all inclusive Docker image that will get your project running very quickly in a production-ready environment.

The image is not meant to be used directly, but to be inherited from. 

It mostly targets the final, production builds, as the build process is too long for quick development iterations. A fresh Perl version is compiled on every build. This image is perfectly suitable for your final CI build step, after which the final image is pushed somewhere for release.

This image is available as a trusted build in [Docker Hub](https://registry.hub.docker.com/u/moltar/perl-app/).

### plenv ###

The image uses [plenv](https://github.com/tokuhirom/plenv) to manage Perl versions. It will read `.perl-version` file from the root of your project directory to get the Perl version to compile.  This file is usually the result of calling `plenv local $PERL_VERSION` in your project root and it is recommended.

If no such file is present, build script will assume and install the latest Perl version, as reported by `plenv install --list` command.

### Carton ###

If your project uses [Carton](https://metacpan.org/pod/Carton), it will be detected and used to install dependencies during Docker image build. Additionally, the build script will try to detect if you have used `carton bundle` and install modules with `--cached` flag, which will significantly speed up the build.

If your project does not use Carton, the build script will simply try to install dependencies via `cpanm --installdeps .` command into the Perl's module directory, rather than `local::lib`.

### Build Hooks ###

Additionally, there are build hooks defined that you can use. If the build script finds these executables in your project root, they will be called.

#### ./before_build ####

As the name suggest, this is called before the build of your project. However, for convenience, it is actually called after Perl is installed. Which means this script can be a regular Perl script if you wish, or Bash, or any other. This hook is useful for installing system pre-reqs for building Perl modules.

#### ./after_build ####

This, of course, is called after the build. It can be used to do general clean up, asset building, etc.

## Usage ##

Create the following files in the same directory or [check out the example repository on GitHub](https://github.com/moltar/docker.perl-app.example).

### Files ###

#### Dockerfile ####

```
FROM moltar/perl-app:latest
ENV PLACK_SERVER HTTP::Server::PSGI
CMD ["plackup"]
EXPOSE 5000
```

#### app.psgi ####

```
#!/usr/bin/env perl

my $app = sub {
    return [200, [], ['Hello World!']];
};
```

#### cpanfile ####

```
requires 'Plack';
```

### Building Docker image ###

```
cd perl-project-dir
plenv local 5.20.4
docker build -t my-perl-project .
docker run my-perl-project
```

## SSH ##

This image is ultimately based on [phusion/baseimage](https://github.com/phusion/baseimage-docker) image, which in turn enables SSH by default. If this is not desired, see instructions on how to [disable SSH](https://github.com/phusion/baseimage-docker#disabling-ssh).

## Tips ##

### .dockerignore ###

Use a `.dockerignore` file to ignore directories that do not need to be part of the image. These directories should be `.git`, `local` (if you are using Carton), possibly other non-Perl project directories. Excluding these will, first of all, prevent you from accidentally sharing something you don't want to share. And also will make your final Docker image smaller.

### .perl-version ###

If you are using Carton for dependency management, it is highly recommended to explicitly set your Perl version in `.perl-version`. You will run into problems installing dependencies in production, when your production Perl version is different from your development. This is a very common pitfall.

## See Also ##

* [moltar/plenv](https://registry.hub.docker.com/u/moltar/plenv/)
* [phusion/baseimage](https://github.com/phusion/baseimage-docker)