{
  cacert,
  fetchgit,
  git,
  lib,
  makeWrapper,
  openssh,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
  versionCheckHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ngit-grasp";
  version = "3.0.2";

  src = fetchgit {
    url = "https://ngit.dev/ngit-grasp.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-eG/8CI6wLZtJJHX6+nRdwBZ6XE7hDi8K2aC1dV4Ldyw=";
  };

  cargoHash = "sha256-ElDej8ZL0rwOQQ3v5DMGtkYglzMmKmADtjijQLZ979E=";

  # Remove these test fixes when a release includes them.
  patches = [
    # https://gitworkshop.dev/nevent1qqswmj2l9wqv8gnmety86n59j6j2vnmdr4rvg3nhlsnadudp4v0nuggpz3mhxue69uhhyetvv9ujumn8d96zuer9wckq48xk
    ./fix-expiry-test.patch
    # https://gitworkshop.dev/nevent1qqsfdx93lyfyyuvw79qg8qe4eec4gjxkqasu3glrrsljhdgle3hw5fqpz3mhxue69uhhyetvv9ujumn8d96zuer9wc67r90d
    ./fix-test-reliability.patch
  ];

  postPatch = ''
    # This test creates its fake Git script at runtime, after shebang patching.
    substituteInPlace tests/git_response_streaming.rs \
      --replace-fail '#!/usr/bin/env bash' '#!${stdenv.shell}'
  '';

  cargoBuildFlags = [
    "-p"
    "ngit-grasp"
  ];

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [ openssl ];

  propagatedUserEnvPkgs = [
    git
    openssh
  ];

  nativeCheckInputs = [
    cacert
    git
  ];

  # Run the package suite, including integration tests with local relay fixtures.
  cargoTestFlags = [
    "-p"
    "ngit-grasp"
  ];

  postInstall = ''
    wrapProgram "$out/bin/ngit-grasp" \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          openssh
        ]
      } \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  versionCheckProgram = "${placeholder "out"}/bin/ngit-grasp";

  meta = {
    description = "GRASP relay for decentralized Git hosting over Nostr";
    homepage = "https://ngit.dev/ngit-grasp";
    changelog = "https://ngit.dev/ngit-grasp/changelog";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ danconwaydev ];
    mainProgram = "ngit-grasp";
    platforms = lib.platforms.unix;
  };
})
