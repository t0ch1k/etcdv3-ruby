{ pkgs, lib, nixpkgs-ruby, ... }:

{
  languages.ruby = {
    enable = true;
    package = nixpkgs-ruby.packages.${pkgs.system}."ruby-3.4";
    bundler.enable = true;

    # Disable Solargraph — we use ruby-lsp from the Gemfile instead
    lsp.enable = false;
  };

  packages = [
    pkgs.git
    pkgs.rubyPackages_3_4.ruby-lsp
    pkgs.etcd_3_5    # etcd server for testing
    pkgs.libyaml     # Required by psych (transitive dep of debug, rails)
  ];

  enterShell = ''
    echo "Ruby $(ruby --version)"
  '';
}
