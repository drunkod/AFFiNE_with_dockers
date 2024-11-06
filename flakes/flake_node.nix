{
  description = "Node.js development environment based on node:20-bookworm-slim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells."${system}".default = pkgs.mkShell {
      packages = with pkgs; [
        # Core dependencies
        nodejs_20
        # dumb-init
        
        # Build essentials
        # pkg-config
        
        # Additional tools that might be useful
        git
        # cacert
      ];

      shellHook = ''

        # Create working directory structure
        export PROJECT_ROOT="$PWD"
        WORK_DIR="/tmp/app"
        if [ ! -d "/tmp/app" ]; then
            mkdir -p "$WORK_DIR"
            chmod 755 "$WORK_DIR"
        fi

        if [ ! -d "$PROJECT_ROOT/build" ]; then
          npm install  
          npm run build
        fi  

        cd /tmp/app

        # Copy configuration files if they exist in the project root
        if [ -f "$PROJECT_ROOT/.npmrc" ]; then
          cp "$PROJECT_ROOT/.npmrc" .
        fi
        
        if [ -f "$PROJECT_ROOT/package.json" ]; then
          cp "$PROJECT_ROOT/package.json" .
        fi
        
        if [ -f "$PROJECT_ROOT/package-lock.json" ]; then
          cp "$PROJECT_ROOT/package-lock.json" .
        fi
        
        if [ -d "$PROJECT_ROOT/patches" ]; then
          cp -r "$PROJECT_ROOT/patches" .
        fi

        # Install production dependencies if package.json exists
        if [ -f "package.json" ]; then
          npm i --only=prod
        fi

        # Copy build directory if it exists
        if [ -d "$PROJECT_ROOT/build" ]; then
              echo "Copying build directory contents..."
                cp -av "$PROJECT_ROOT/build/." . || {
                echo "Failed to copy build directory contents"
                return 1
                }
        fi

        # Set up environment variables
        export NODE_ENV=production
        
        # Print environment info
        echo "Node.js version: $(node --version)"
        echo "npm version: $(npm --version)"
        echo "Working directory: $(pwd)"

        # Function to start the application
        start_app() {
            npm start
        }

        echo "To start the application, run: start_app"
      '';
    };

    # Optional: Add a package definition if you want to build it
    packages."${system}".default = pkgs.stdenv.mkDerivation {
      name = "node-app";
      src = ./.;
      
      buildInputs = with pkgs; [
        nodejs_20
      ];

      buildPhase = ''
            # Create app directory structure
            mkdir -p $out/app/static/admin
            mkdir -p $out/app/static/mobile

            # Copy backend server
            cp -r ${./packages/backend/server}/* $out/app/

            # Copy frontend builds
            cp -r ${./packages/frontend/apps/web/dist}/* $out/app/static/
            cp -r ${./packages/frontend/admin/dist}/* $out/app/static/admin/
            cp -r ${./packages/frontend/apps/mobile/dist}/* $out/app/static/mobile/
           
      '';

      installPhase = ''
            mkdir -p $out/bin

            # Create wrapper script
            cat > $out/bin/start-app <<EOF
            #!${pkgs.bash}/bin/bash
            cd $out/app
            exec ${pkgs.nodejs_20}/bin/node --import ./scripts/register.js ./dist/index.js
            EOF

            chmod +x $out/bin/start-app
      '';
    };
  };
}