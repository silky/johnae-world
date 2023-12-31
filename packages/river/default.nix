{
  lib,
  stdenv,
  inputs,
  libevdev,
  libGL,
  libinput,
  libX11,
  libxkbcommon,
  pixman,
  pkg-config,
  scdoc,
  udev,
  wayland,
  wayland-protocols,
  wlroots_0_16,
  xwayland,
  zig,
  withManpages ? true,
  xwaylandSupport ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "river";
  version = inputs.river.rev;

  outputs = ["out"] ++ lib.optionals withManpages ["man"];

  src = inputs.river;

  nativeBuildInputs =
    [
      pkg-config
      wayland
      xwayland
      zig.hook
    ]
    ++ lib.optional withManpages scdoc;

  buildInputs =
    [
      libGL
      libevdev
      libinput
      libxkbcommon
      pixman
      udev
      wayland-protocols
      wlroots_0_16
    ]
    ++ lib.optional xwaylandSupport libX11;

  dontConfigure = true;

  zigBuildFlags =
    lib.optional withManpages "-Dman-pages"
    ++ lib.optional xwaylandSupport "-Dxwayland";

  postInstall = ''
    install contrib/river.desktop -Dt $out/share/wayland-sessions
  '';

  passthru.providedSessions = ["river"];

  meta = {
    homepage = "https://github.com/ifreund/river";
    description = "A dynamic tiling wayland compositor";
    longDescription = ''
      River is a dynamic tiling Wayland compositor with flexible runtime
      configuration.

      Its design goals are:
      - Simple and predictable behavior, river should be easy to use and have a
        low cognitive load.
      - Window management based on a stack of views and tags.
      - Dynamic layouts generated by external, user-written executables. A
        default rivertile layout generator is provided.
      - Scriptable configuration and control through a custom Wayland protocol
        and separate riverctl binary implementing it.
    '';
    changelog = "https://github.com/ifreund/river/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [
      adamcstephens
      fortuneteller2k
      rodrgz
    ];
    mainProgram = "river";
    platforms = lib.platforms.linux;
  };
})