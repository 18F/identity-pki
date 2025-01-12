{
  description = "DevShell for identity-pki";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShell =
          with pkgs;

          mkShell {
            buildInputs = [
              ruby
              yarn
              postgresql.dev
              goreman # Use goreman since nginx launch will fail gracefully and launch Puma, as opposed to when using foreman
              # nginx
            ];

            shellHook = ''
              export PKG_CONFIG_PATH="${pkgs.postgresql.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
            '';
          };
      }
    );
}
