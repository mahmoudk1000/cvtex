{
  description = "cvtex - LaTeX CV";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          
          # Create a derivation for all custom fonts
          customFonts = pkgs.stdenv.mkDerivation {
            name = "custom-fonts";
            src = ./fonts;
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              mkdir -p $out/share/fonts/truetype
              
              find . -name "*.otf" -exec cp {} $out/share/fonts/opentype/ \;
              find . -name "*.ttf" -exec cp {} $out/share/fonts/truetype/ \;
              
              echo "Installed fonts:"
              ls -la $out/share/fonts/opentype/
              ls -la $out/share/fonts/truetype/
            '';
          };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            name = "cvtex";
            src = ./.;
            buildInputs = with pkgs; [ texliveFull fontconfig customFonts ];
            buildPhase = ''
              export HOME=$(mktemp -d)
              
              export FONTCONFIG_FILE=${pkgs.makeFontsConf { fontDirectories = [ customFonts ]; }}
              mkdir -p $HOME/.cache/fontconfig
              ${pkgs.fontconfig}/bin/fc-cache -f
              
              mkdir -p .cache/latex
              
              # Build the PDF with XeLaTeX (required for fontspec)
              latexmk -interaction=nonstopmode -auxdir=.cache/latex -xelatex resume.tex
            '';
            installPhase = ''
              mkdir -p $out
              cp resume.pdf $out/mahmoud_farouk-devops-sre.pdf
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          
          # Create a derivation for all custom fonts
          customFonts = pkgs.stdenv.mkDerivation {
            name = "custom-fonts";
            src = ./fonts;
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              mkdir -p $out/share/fonts/truetype
              
              # Install all font files dynamically
              find . -name "*.otf" -exec cp {} $out/share/fonts/opentype/ \;
              find . -name "*.ttf" -exec cp {} $out/share/fonts/truetype/ \;
              
              # List installed fonts for debugging
              echo "Installed fonts:"
              ls -la $out/share/fonts/opentype/
              ls -la $out/share/fonts/truetype/
            '';
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              texliveFull
              latexmk
              fontconfig
              customFonts
            ];
            shellHook = ''
              export FONTCONFIG_FILE=${pkgs.makeFontsConf { fontDirectories = [ customFonts ]; }}
              ${pkgs.fontconfig}/bin/fc-cache -f
              echo "LaTeX development shell ready with custom fonts available."
              echo "Available custom fonts:"
              fc-list | grep -E "\.(otf|ttf)" || echo "Font cache may need time to update..."
              echo "All available fonts:"
              fc-list : family
            '';
          };
        }
      );
    };
}
