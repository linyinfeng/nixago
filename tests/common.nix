{ pkgs, plugins }:
path: expected: config:
let
  parts = pkgs.lib.splitString "." path;
  plugin = builtins.elemAt parts 0;
  make = pkgs.lib.getAttrFromPath parts plugins;
  output = make config;

  result = pkgs.runCommand "test.${plugin}"
    { }
    ''
      cmp "${expected}" "${output.configFile}"
      touch $out
    '';
in
result