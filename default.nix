{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.blurcam;

in {
	options.services.blurcam = {
		input = mkOption {
			default = "/dev/video0";
			type = types.str;
			description = "Video input file";
		};

		output = mkOption {
			default = "/dev/video4";
			type = types.str;
			description = "Video output file";
		};

		sigma = mkOption {
			default = 0.5;
			type = types.float;
			description = "Gaussian blur sigma value";
		};

		width = mkOption {
			default = -2;
			type = types.int;
			description = "Width to scale to";
		};

		height = mkOption {
			default = 120;
			type = types.int;
			description = "Height to scale to";
		};

		preamble = mkOption {
			default = "";
			example = ''
				 v4l2-ctl="$${pkgs.v4l_utils}/bin/v4l2-ctl"
				$v4l2-ctl -d /dev/video0 --set-fmt-video "width=640,height=480"
			'';
			type = types.lines;
			description = "Shell to execute before blurcam";
		};
	};

	config = mkIf (cfg.input != "" && cfg.output != "") {
		boot.extraModulePackages = with config.boot.kernelPackages; [
			v4l2loopback
		];

		boot.extraModprobeConfig = ''
			options v4l2loopback video_nr=4 exclusive_caps=1
		'';

		systemd.services.blurcam =
			let script = pkgs.writeScriptBin "blurcam_wrapper"
				''#!${pkgs.stdenv.shell}
					set -e
					${cfg.preamble}
					${./blurcam} ${escapeShellArg cfg.input} ${escapeShellArg cfg.output}
				'';

				targets = [
					"multi-user.target"
					"hybrid-sleep.target"
					"hibernate.target"
					"suspend.target"
					"suspend-then-hibernate.target"
				];

			in {
				description = "Blurcam daemon";
				wantedBy = targets;
				after    = targets;
				serviceConfig = {
					Type = "simple";
					ExecStart = "${script}/bin/blurcam_wrapper";
					User  = "root";
					Group = "video";
					NoNewPrivileges = true;
					PrivateDevices  = false;
					ProtectHome     = true;
					ProtectSystem   = "strict";
					ReadWriteDirectories = cfg.output;
				};
				environment = {
					BLURCAM_SIGMA  = (toString cfg.sigma);
					BLURCAM_WIDTH  = (toString cfg.width);
					BLURCAM_HEIGHT = (toString cfg.height);
				};
				path = with pkgs; [ ffmpeg kmod bash ];
			};
	};
}
