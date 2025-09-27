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
        in
        {
          default = pkgs.stdenv.mkDerivation {
            name = "cvtex";
            src = ./.;
            buildInputs = with pkgs; [ texliveFull ];
            buildPhase = ''
              export HOME=$(mktemp -d)
              mkdir -p .cache/latex
              latexmk -interaction=nonstopmode -auxdir=.cache/latex -pdf main.tex
            '';
            installPhase = ''
              mkdir -p $out
              cp main.pdf $out/mahmoud_farouk-devops-sre.pdf
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              texliveFull
              latexmk
            ];
            shellHook = ''
              echo "LaTeX development shell ready."
            '';
          };
        }
      );
    };
}
