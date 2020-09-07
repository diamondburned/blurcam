# blurcam

Script to blur a camera, aka my-near-sightedness-simulator.

## Usage

Dependencies: `bash`, `ffmpeg`, `kmod`.

```sh
nix-shell
./blurcam /dev/video0 /dev/video4
```

## Nix usage

```nix
{ config, pkgs, lib, ... }:

let blurcam = builtins.fetchGit {
	url = "https://github.com/diamondburned/blurcam.git";
	rev = "9275eeb55925bd6487b52e8eea0741e5143cdd17"; # update this
};

in {
	imports = [ "${blurcam}" ];

	services.blurcam = {
		input  = "/dev/video0";
		output = "/dev/video4";
		# Example preamble.
		preamble = ''
			 ctl="${pkgs.v4l_utils}/bin/v4l2-ctl"
			$ctl -d /dev/video0 --set-fmt-video "width=640,height=480"
			$ctl -d /dev/video0 -c "power_line_frequency=0,sharpness=100,saturation=25,contrast=40,brightness=100"
		'';
	};
}
```
