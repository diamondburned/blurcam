{ config, lib, pkgs, ... }:

with lib;

let cfg     = config.services.blurcam;
	package = pkgs.callPackage ./shell.nix {};

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
					${./blurcam} "${cfg.input}" "${cfg.output}"
				'';

			in {
				description = "Blurcam daemon";
				wantedBy = [ "multi-user.target" ];
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
				path = with pkgs; [ ffmpeg kmod bash ];
			};
	};
}
