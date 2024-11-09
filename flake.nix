{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    prisma-utils.url = "github:VanCoding/nix-prisma-utils";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    prisma-utils,
    treefmt-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;}
    {
      imports = [
        treefmt-nix.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        pkgs,
        self',
        lib,
        ...
      }:
      #  let
      # https://github.com/VanCoding/nix-prisma-utils/issues/5
      # prisma =
      #   (prisma-utils.lib.prisma-factory {
      #     nixpkgs = pkgs;
      #     prisma-fmt-hash = "sha256-4zsJv0PW8FkGfiiv/9g0y5xWNjmRWD8Q2l2blSSBY3s="; # just copy these hashes for now, and then change them when nix complains about the mismatch
      #     query-engine-hash = "sha256-6ILWB6ZmK4ac6SgAtqCkZKHbQANmcqpWO92U8CfkFzw=";
      #     libquery-engine-hash = "sha256-n9IimBruqpDJStlEbCJ8nsk8L9dDW95ug+gz9DHS1Lc=";
      #     schema-engine-hash = "sha256-j38xSXOBwAjIdIpbSTkFJijby6OGWCoAx+xZyms/34Q=";
      #   })
      #   .fromPnpmLock
      #   ./backend/pnpm-lock.yaml;
      # in
      {
        devShells = let
          bareMinimum = with pkgs; [corepack just nodejs_20 git yarn rustup];
        in {
          default = pkgs.mkShell {
            nativeBuildInputs =
              bareMinimum
              ++ (with pkgs; [
                prisma-engines
                openssl
              ]);
            # shellHook = prisma.shellHook;
            shellHook = ''
              export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
              export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
              export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
              export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
              export PATH="$PWD/node_modules/.bin/:$PATH"
            '';
          };

          build = pkgs.mkShell {
            nativeBuildInputs =
              bareMinimum
              ++ (with pkgs; [
                prisma-engines
                openssl
              ]);
            # shellHook = prisma.shellHook;
            shellHook = ''
              export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
              export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
              export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
              export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
              # export PATH="$PWD/backend/node_modules/.bin/:$PATH"
              export PATH="$PWD/node_modules/.bin/:$PATH"

              corepack prepare yarn@stable --activate

              # install dependencies
              yarn install

              # It will build the native module at /packages/frontend/native
              #  and build Node.js binding using NAPI.rs. 
              yarn workspace @affine/native build

              # Build Server Dependencies
              yarn workspace @affine/server-native build

              BUILD_TYPE=canary yarn workspace @affine/web build
              BUILD_TYPE=canary yarn workspace @affine/admin build
              BUILD_TYPE=canary yarn workspace @affine/mobile build
              BUILD_TYPE=canary yarn workspace @affine/server build
            '';
          };

          docker = pkgs.mkShell {
            nativeBuildInputs =
              bareMinimum
              ++ (with pkgs; [
                prisma-engines
                openssl
              ]);
            # shellHook = prisma.shellHook;
            shellHook = ''
              export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
              export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
              export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
              export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
              # export PATH="$PWD/backend/node_modules/.bin/:$PATH"
              export PATH="$PWD/node_modules/.bin/:$PATH"
              # Create the necessary directories
              mkdir -p app/static
              mkdir -p app/static/admin
              mkdir -p app/static/mobile

              # Copy backend server files
              cp -r ./packages/backend/server/. app

              # Copy frontend web app files
              cp -r ./packages/frontend/apps/web/dist/. app/static

              # Copy frontend admin app files
              cp -r ./packages/frontend/admin/dist/. app/static/admin

              # Copy frontend mobile app files
              cp -r ./packages/frontend/apps/mobile/dist/. app/static/mobile

              cd app

              # Run the Node.js application
              # node --import ./scripts/register.js ./dist/index.js
              # affine_selfhosted
              # node ./scripts/self-host-predeploy && node ./dist/index.js 
            '';
          };   

          ci-format = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [corepack];
          };

          ci-reviewdog = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              corepack
              nodejs_22
            ];
          };
        };

        treefmt = {
          projectRootFile = "flake.nix";

          programs = {
            alejandra.enable = true;
            yamlfmt.enable = true;
            csharpier.enable = true;
            # Manage using ci instead
            # prettier.enable = true;
          };
        };
      };
    };
}
