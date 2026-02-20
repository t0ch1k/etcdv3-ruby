{ pkgs, lib, nixpkgs-ruby, ... }:

{
  languages.ruby = {
    enable = true;
    package = nixpkgs-ruby.packages.${pkgs.system}."ruby-3.2";
    bundler.enable = true;

    # Disable Solargraph — we use ruby-lsp from the Gemfile instead
    lsp.enable = false;
  };

  packages = [
    pkgs.git

    pkgs.libyaml     # Required by psych (transitive dep of debug, rails)
  ];

  enterShell = ''
    echo "Ruby $(ruby --version)"
  '';
}
