> This is partially not completed yet.
>
> However, it works most of the time, as long as you do not want different defaults.
>
> Below is how it shall look like in future.

# LXC unprivileged containers

This works around several shortcomings of LXC and mmdebstrap:

- The way how to create working unprivileged containers is barely documented.  This here sums it up.
- The mapped UIDs are taken from `~/.config/lxc/default.conf` instead of `/etc/subuid`+`/etc/subgid`
- The latter are registries and can only be changed by `root`
- while `default.conf` can be created by you as you like it.
- `~/.config/lxc/default.conf` is way to complex for normal users, so this is can be created for you.
- There are interactive questions to setup your LXC directory.
- You can have different LXC directories which can share parts of the configuration etc.


## Usage

	cd
	git clone https://github.com/hilbix/LXC.git
	./lxc.sh
	# Follow the white rabbit

Later you can do:

	./lxc.sh $CONTAINER ${TYPE:-DEFAULT}

There are no complex options.  Just run it and follow the white rabbit.


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

