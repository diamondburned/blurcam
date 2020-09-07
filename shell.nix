{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
	name = "blurcam";
	buildInputs = with pkgs; [ ffmpeg kmod bash ];
}
