{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:Vonfry/poetry2nix/update/ruff";
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
          default = mkPoetryApplication {
            projectDir = self;
            groups = [ "dev" "local" "ui" ];
            prePatch = ''
              substituteInPlace ./private_gpt/constants.py --replace "Path(__file__).parents[1]" "Path(os.environ.get('PROJECT_ROOT_PATH', os.getcwd()))"
              echo "import os" | cat - ./private_gpt/constants.py > temp && mv temp ./private_gpt/constants.py
              cat ./private_gpt/constants.py
            '';
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
                #rpds-py = super.rpds-py.overridePythonAttrs
                #  (
                #    old: {
                #      cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
                #        inherit (old) src;
                #        name = "${old.pname}-${old.version}";
                #        hash = "sha256-jdr0xN3Pd/bCoKfLLFNGXHJ+G1ORAft6/W7VS3PbdHs=";
                #      };
                #    }
                #  );
                pypika = super.pypika.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                evaluate = super.evaluate.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                sentence-transformers = super.sentence-transformers.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                optimum = super.optimum.overridePythonAttrs
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
                llama-cpp-python = (super.llama-cpp-python.overridePythonAttrs
                  (
                    old: {
                      CMAKE_ARGS = "-DLLAMA_CUBLAS=on";
                      buildInputs = (old.buildInputs or []) ++ [ pkgs.cudaPackages.libcublas pkgs.cudaPackages.cudatoolkit.lib ];
                      propagatedBuildInputs = builtins.filter (e: e.pname != "cmake") old.propagatedBuildInputs ++ [ super.scikit-build-core super.pyproject-metadata super.pathspec ];
                      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ super.scikit-build-core super.pyproject-metadata pkgs.cudaPackages.cudatoolkit ];
                    }
                  )).override { stdenv = pkgs.gcc11Stdenv; };
                onnx = pkgs.onnxruntime;
#                    super.onnx.overridePythonAttrs
#                  (
#                    old: {
#                      cmakeFlags = (old.cmakeFlags or []) ++ [
#                        "-DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=ALWAYS"
#                        "-DFETCHCONTENT_FULLY_DISCONNECTED=1"
#                      ];
#                      buildInputs = (old.buildInputs or [ ]) ++ [
#                        pkgs.abseil-cpp
#                      ];
#                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.cmake ];
#                    }
#                  );
                pydantic-extra-types = super.pydantic-extra-types.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.hatchling ];
                    }
                  );
                pyarrow-hotfix = super.pyarrow-hotfix.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.hatchling ];
                    }
                  );
                sympy = super.sympy.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.hatchling ];
                    }
                  );
#                nvidia-cusparse-cu12 = super.nvidia-cusparse-cu12.overridePythonAttrs
#                  (
#                    old: {
#                      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.cudaPackages.libnvjitlink ];
#                    }
#                  );
#                nvidia-cusolver-cu12 = super.nvidia-cusolver-cu12.overridePythonAttrs
#                  (
#                    old: {
#                      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.cudaPackages.libnvjitlink pkgs.cudaPackages.libcublas pkgs.cudaPackages.libcusparse ];
#                    }
#                  );
                nvidia-cusparse-cu12 = pkgs.cudaPackages.libcusparse;
                nvidia-cusolver-cu12 = pkgs.cudaPackages.libcusolver;
                tokenizers = super.tokenizers.overridePythonAttrs
                  (
                    old: rec {
                      src = pkgs.fetchFromGitHub {
                        owner = "huggingface";
                        repo = "tokenizers";
                        rev = "refs/tags/v0.15.0";
                        hash = "sha256-+yfX12eKtgZV1OQvPOlMVTONbpFuigHcl4SjoCIZkSk=";
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
                      cargoDeps = pkgs.rustPlatform.importCargoLock {
                        lockFile = "${super.ruff.src}/Cargo.lock";
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
