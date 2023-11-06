{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:pegasust/poetry2nix/orjson";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides mkPoetryEnv;
      in
      rec {
        packages = {
          default = mkPoetryEnv {
            projectDir = self;
            extraPackages = p: with p; [ gradio ];
            overrides = defaultPoetryOverrides.extend
              (self: super: {

                chroma-hnswlib = super.chroma-hnswlib.override { preferWheel = true; };
                chromadb = super.chromadb.override { preferWheel = true; };
                cmake = pkgs.python3Packages.cmake;
                gradio = super.gradio.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.hatch-requirements-txt super.hatch-fancy-pypi-readme ];
                    }
                  );
                gradio-client = super.gradio-client.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.hatch-requirements-txt super.hatch-fancy-pypi-readme ];
                    }
                  );
                rpds-py = super.rpds-py.overridePythonAttrs
                  (
                    old: {
                      cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
                        inherit (old) src;
                        name = "${old.pname}-${old.version}";
                        hash = "sha256-jdr0xN3Pd/bCoKfLLFNGXHJ+G1ORAft6/W7VS3PbdHs=";
                      };
                    }
                  );
                pypika = super.pypika.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                llama-index = super.llama-index.overridePythonAttrs
                  (
                    old: {
                      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ self.tiktoken super.setuptools ];
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.poetry ];
                    }
                  );
                pydantic-extra-types = super.pydantic-extra-types.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.hatchling ];
                    }
                  );
                tokenizers = super.tokenizers.overridePythonAttrs
                  (
                    old: {
                      sourceRoot = "tokenizers-0.14.1/bindings/python";
                      cargoDeps = pkgs.rustPlatform.importCargoLock {
                        lockFile = ./nix/tokenizers/Cargo.lock;
                      };
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                        pkgs.rustPlatform.cargoSetupHook
                        pkgs.rustPlatform.maturinBuildHook
                      ];
                    }
                  );
                tiktoken = super.tiktoken.overridePythonAttrs
                  (
                    old: {
                      postPatch = ''
                        ln -s ${./nix/tiktoken/Cargo.lock} Cargo.lock
                       '';
                      cargoDeps = pkgs.rustPlatform.importCargoLock {
                        lockFile = ./nix/tiktoken/Cargo.lock;
                      };
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                        pkgs.rustPlatform.cargoSetupHook
                        pkgs.rustc
                        pkgs.cargo
                        super.setuptools-rust
                      ];
                    }
                  );
                ruff = super.ruff.overridePythonAttrs
                  (
                    old: {
                      postPatch = ''
                        cp ${./nix/ruff/Cargo.lock} Cargo.lock
                       '';
                      cargoDeps = pkgs.rustPlatform.importCargoLock {
                        lockFile = ./nix/ruff/Cargo.lock;
                      };
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                        pkgs.rustPlatform.cargoSetupHook
                        pkgs.rustPlatform.maturinBuildHook
                      ];
                    }
                  );
              });
          };
        };
        devShells.foo = pkgs.mkShell {
          buildInputs = [ packages.default ];
        };
      });
}
