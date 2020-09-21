> **This is partially incomplete!**
>
> Some features/commands/etc. noted below not yet exist.


# LXC unprivileged containers

This is not meant for Cubernetes or similar to run Linux containers on system level.
Instead this is entirely meant to run Linux containers on user level only.

This repository works around several shortcomings of plain LXC and mmdebstrap:

- The way how to create working unprivileged containers from scratch is barely documented.
- `~/.config/lxc/default.conf` can be automatically created for you.
- The mapped UIDs are taken from the container config and not from `/etc/subuid`+`/etc/subgid` as usual
  - The latter are registries and can only be changed by `root`
  - while `default.conf` can be changed (based on what is allowed in the registry) by you as you like.
- ~~There are interactive menus to all setup questions like your LXC directory.~~
- You can have more than one checkouts (of this repository), which then can have indipendent setups.


## Usage

Be sure that everything in `lxc-checkconfig` (run it as normal user) is green.  Following two yellow lines can be ignored:

	CONFIG_NF_NAT_IPV4: missing
	CONFIG_NF_NAT_IPV6: missing

For more information how to prepare networking on system level see: https://wiki.debian.org/LXC

To install:

	cd
	git clone https://github.com/hilbix/LXC.git
	LXC/bin/setup.sh LXC	# installs $HOME/bin/LXC as a wrapper command

`setup` prints everything you need to change on your system to successfully run unprivileged LXC containers.

Following assumes that `$HOME/bin/` is in your `$PATH` and you ran setup as shown above.

To create a container with default values:

	LXC create CONTAINER

To run a command in the container:

	LXC run CONTAINER command args..
	# creates `LXC/CFG/CONTAINER.sh`.

Additional commands:

	LXC start CONTAINER	# start container
	LXC stop CONTAINER	# stop container
	LXC run CONTAINER cmd	# run CMD in container
	LXC root CONTAINER cmd	# run CMD in container as root
	LXC list		# list all containers
	LXC stop		# list started containers
	LXC start		# list stopped containers

Notes:

- `run` starts the container if it is not already running
  - it cannot stop the container, though, as you can always interrupt things

There are no complex options.  Just invoke a command and follow the white rabbit.  However ..

.. for now commands are not yet interactive.  So all options must be given via environment.
In future this will keep the same if stdin is not a TTY (if invoked with `</dev/null`).

For all the parameters see Usage output (for example run `LXC create`).
Either use `export` to set variables or set them with the commandline, as usual:

	LXC_INCLUDE=emacs LXC create test


## Directories

- `bin/` use softlinks to the scripts there or add this directory to `$PATH`
  - usually `bin/lxc.sh` is linked to `~/bin/LXC`, but name does not matter
- `lxc-inc/` are common includes for the scripts, position autodetected from the softlinks
- `wrap/` are the templates for the wrappers generated in `CFG/`
- `CFG` will be created by the scripts and is normally a softlink to `~/.config/lxc`
- `LXC` will be created by the scripts and is normallt a softlink to `~/.local/share/lxc`


## FAQ

Follow the White Rabbit?

- Knock Knock, Neo, which pill?
- Eat me, Alice, or drink me?

WTF why?

- Because I need it.
- I am too anxious to run dangerous things (like Docker) outside of some securing container (even then it stays very risky).

Secure?

- This is true for things which come from DockerHub or similar external repositories.
- This here should be as secure as Debian and `lxc-nsuserexec`, as it only uses what is already builtin into your OS.
- Unlike `lxc-create -t download` it does not use any additional and possibly dangerous external third party sources or registry.
- Running things like Maven/Bower/Android Studio outside of containers is like a Bungee Jump without rope.
- But even with a rope it stays extremely dangerous, like driving an old car without Belts'n'Airbags.
- Even if containers might protect you by chance, it still might hurt others.  It's like not wearing a COVID19 Mask.
- Hence this here does not magically protect you or yours somehow.  You still have to stay alert.
- However it helps your to implement clean and easy to understand additinal security barriers under your control.

License?

- Free as free beer, free speech, free baby.

Patches?  Contrib?

- Create a PR on GitHub.
- Stick to the license and waive all copyright.
- Eventually I listen.

Contact?  Question?

- Create an issue on GitHub.
- Eventually I listen.

