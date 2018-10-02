static-glibc-nginx
==================

This repository contains a Makefile and patches to produce a fully statically
linked NGINX binary. To achieve this, functions depending on
[Name Service Switch][NSS] have been disabled which may cause NGINX to not
behave as expected under certain conditions. If the NGINX binary encounters a
code path where a function has been disabled, a message ending in "...disabled
for static build" will be logged. Starting NGINX as an unprivileged user may be
used to avoid some of these code paths.

  [NSS]: https://en.wikipedia.org/wiki/Name_Service_Switch

Licensing
---------

The Makefile and NGINX patch are licensed under the
[2-clause BSD license][BSD].

  [BSD]: http://opensource.org/licenses/BSD-2-Clause

Instructions
------------

To build NGINX binary, simply run `make` (which is implicitly `make all`)
inside the root of the repository. The statically linked binary and all of its
configuration dependencies will be placed in a folder named "nginx". If the
NGINX binary / its folder is relocated, use the
["-p" flag](http://wiki.nginx.org/CommandLine) to point NGINX to the correct
directory.

Some of the other targets provided by the Makefile include:

- **clean**: Delete all folders created by this script.
- **cleaner**: Delete all files created by this script which includes the
  downloaded tar-balls.
- **deps**: Install dependencies required to compile NGINX. This target will
  only work on Red Hat and Debian-based systems and must be used while running
  as root.

Attributions
------------

The following scripts were referenced when creating this project:

- [Gist: nlindblad/build-nginx.sh](https://gist.github.com/nlindblad/9709182)
- [Gist:  rjeczalik/building-static-nginx.txt](https://gist.github.com/rjeczalik/7057434)
