{
  stdenv,
  blur,
  bash,
  jq,
  grim,
  sway,
  swaylock,
  writeShellApplication,
  lib,
}:
writeShellApplication {
  name = "swaylock-dope";
  text = builtins.readFile ./swaylock-dope;
  runtimeInputs = [blur jq grim sway swaylock];
}
