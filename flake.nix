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
        pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides mkPoetryEnv;
      in
      rec {
        packages = {
          default = mkPoetryEnv {
            projectDir = self;
            extraPackages = p: with p; [ gradio ];
            groups = [ "dev" "local" ];
            overrides = defaultPoetryOverrides.extend
              (self: super: {

                chroma-hnswlib = super.chroma-hnswlib.override { preferWheel = true; };
                chromadb = super.chromadb.override { preferWheel = true; };
                cmake = pkgs.python3Packages.cmake;
                safetensors = pkgs.python3Packages.safetensors;
                triton = super.triton.overridePythonAttrs
                  (
                    old: {
                      propagatedBuildInputs = builtins.filter (e: e.pname != "cmake") old.propagatedBuildInputs;
                    }
                  );
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
                scipy = super.scipy.overridePythonAttrs
                  (
                    old: {
                      preConfigure = "";
                    }
                  );
                llama-index = super.llama-index.overridePythonAttrs
                  (
                    old: {
                      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ self.tiktoken super.setuptools ];
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.poetry ];
                    }
                  );
                llama-cpp-python = super.llama-cpp-python.overridePythonAttrs
                  (
                    old: {
                      cmakeFlags = [
                        "-DLLAMA_CUBLAS=on"
                      ];
                      buildInputs = (old.buildInputs or []) ++ [ pkgs.cudaPackages.cudatoolkit.out pkgs.cudaPackages.cudatoolkit.lib ];
                      propagatedBuildInputs = builtins.filter (e: e.pname != "cmake") old.propagatedBuildInputs ++ [ super.scikit-build-core super.pyproject-metadata super.pathspec ];
                      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ super.scikit-build-core super.pyproject-metadata ];
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
                    old: rec {
                      src = pkgs.fetchFromGitHub {
                        owner = "huggingface";
                        repo = "tokenizers";
                        rev = "refs/tags/v0.14.0";
                        hash = "sha256-zCpKNMzIdQ0lLWdn4cENtBEMTA7+fg+N6wQGvio9llE=";
                      };
                      postPatch = ''
                        cd bindings/python
                      '';
                      cargoDeps = pkgs.rustPlatform.importCargoLock {
                        lockFile = "${src}/bindings/python/Cargo.lock";
                      };
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                        pkgs.rustPlatform.cargoSetupHook
                        pkgs.rustPlatform.maturinBuildHook
                      ];
                    }
                  );
                #safetensors = super.safetensors.overridePythonAttrs
                #  (
                #    old: {
                #      sourceRoot = "safetensors-0.4.0/bindings/python";
                #      cargoDeps = pkgs.rustPlatform.importCargoLock {
                #        lockFile = ./nix/safetensors/Cargo.lock;
                #      };
                #      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                #        pkgs.rustPlatform.cargoSetupHook
                #        pkgs.rustPlatform.maturinBuildHook
                #      ];
                #    }
                #  );
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
        devShells.default = pkgs.mkShell {
          buildInputs = [ packages.default ];
        };
      });
}
