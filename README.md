> **This is partially incomplete!**
>
> Some features/commands/etc. noted below might not exist yet.


# LXC unprivileged containers

This works around several shortcomings of LXC and mmdebstrap:

- The way how to create working unprivileged containers from scratch is barely documented.
- `~/.config/lxc/default.conf` can be automatically created for you.
- The mapped UIDs are taken from the container config and not from `/etc/subuid`+`/etc/subgid` as usual
  - The latter are registries and can only be changed by `root`
  - while `default.conf` can be changed (based on what is allowed in the registry) by you as you like.
- ~~There are interactive menus to all setup questions like your LXC directory.~~
- You can have more than one checkouts (of this here) which then can have indipendent setups.

This is not for things like Cubernetes or on system level.  This is meant entirely on user level.

- LXC networking should be set up, see https://wiki.debian.org/LXC


## Usage

See also: https://wiki.debian.org/LXC

Following must be prepared as `root` user (this is for Debian or Ubuntu):

```
apt-get install lxc uidmap mmdebstrap debian-archive-keyring

[ -f /etc/default/lxc-net ] || echo 'USE_LXC_BRIDGE="true"' >> /etc/default/lxc-net

fgrep `lxc.net.0` /etc/lxc/default.conf || cat <<EOF >>/etc/lxc/default.conf
# lxcbr0 is the default LXC bridge                                                                                                            
# ETH Vendor 00163e is XENsource INC
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
EOF

systemctl enable lxc-net
systemctl restart lxc-net

echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/80-lxc-userns.conf
sysctl --system
```

For each user allowed to use lxc-start (`$(id -u -n)` below refers to the user's login), do:

printf '\n%q\t%q\t%q\t%q\n' "$(id -u -n)" veth lxcbr0 10 | sudo tee -a /etc/lxc/lxc-usernet

Then, as the user:

	cd
	git clone https://github.com/hilbix/LXC.git
	ln -s --relative LXC/bin/lxc.sh ~/bin/LXC
	LXC setup

This initializes everything and shows you the usage.  Then:

	LXC create CONTAINER

To run a command in the container:

	LXC run CONTAINER command args..
	# creates `LXC/CONF/CONTAINER.sh`.

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


## FAQ

Follow the White Rabbit?

- Knock Knock, Neo, which pill?
- Eat me, Alice, or drink me?

WTF why?

- Because I need it.

Secure?

- This here should be as secure as Debian and `lxc-nsuserexec`, as it only uses what is already builtin into your OS.
- Unlike `lxc-create -t download` it does not use any additional and possibly dangerous external third party source or registry.
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

