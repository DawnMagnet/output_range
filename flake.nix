{
  description = "A simple C++ header file to allow outputting of C++ ranges";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Since this is a header-only library, we'll create a simple derivation
      application =
        { pkgs }:
        pkgs.stdenv.mkDerivation {
          pname = "output-range";
          version = "1.0.0";

          src = ./.;

          # Header-only library, no build required
          dontBuild = true;
          dontConfigure = true;

          installPhase = ''
            mkdir -p $out/include
            cp *.h $out/include/
          '';

          meta = with pkgs.lib; {
            homepage = "https://github.com/DawnMagnet/output_range";
            description = "A simple C++ header file to allow outputting of C++ ranges";
            license = licenses.unlicense;
            platforms = platforms.all;
            maintainers = [ ];
          };
        };

      # Development environment for working with the library
      dev-env =
        { pkgs, stdenv }:
        let
          app = application { inherit pkgs; };
        in
        pkgs.mkShell.override { inherit stdenv; } {
          name = "output-range-dev";
          nativeBuildInputs = app.buildInputs or [ ];

          # Set up environment for development
          shellHook = ''
            echo "output_range development environment"
            echo "Header files available in: ${app}/include"
            echo ""
            echo "Available compilers:"
            echo "  - g++: $(g++ --version | head -n1)"
            echo "  - clang++: $(clang++ --version | head -n1)"
            echo ""
            echo "Use 'clang++ -std=c++17 -I${app}/include your_file.cpp' to compile with this library"
          '';
        };

    in
    {
      overlays.default = final: prev: {
        output-range = application { pkgs = final; };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          default = pkgs.output-range;
          output-range = pkgs.output-range;
        };

        devShells = rec {
          # GCC-based development shell
          gcc = dev-env {
            inherit pkgs;
            stdenv = pkgs.stdenv;
          };

          # Clang-based development shell
          clang = dev-env {
            inherit pkgs;
            stdenv = pkgs.libcxxStdenv;
          };

          # Default development shell (GCC)
          default = gcc;
        };

        # Apps for easy access
        apps = {
          # Example app to show how to use the library
          example = {
            type = "app";
            program = pkgs.writeShellScript "output-range-example" ''
              cat << 'EOF'
              Example usage of output_range:

              #include <iostream>
              #include <vector>
              #include <ostream_range.h>

              int main() {
                  std::vector<int> v = {1, 2, 3, 4, 5};
                  std::cout << "Vector: " << v << std::endl;
                  return 0;
              }
              EOF
            '';
          };
        };
      }
    );
}
