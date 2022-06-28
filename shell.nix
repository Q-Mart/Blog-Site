with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "env";

  buildInputs = [
    bashInteractive
    libxml2
    zlib
  ];

  nativeBuildInputs = [
    bundler
  ];
}
