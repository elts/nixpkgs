{ stdenv, lib, fetchurl
, SDL, dwarf-fortress-unfuck
}:

let
  baseVersion = "44";
  patchVersion = "05";
  dfVersion = "0.${baseVersion}.${patchVersion}";
  libpath = lib.makeLibraryPath [ stdenv.cc.cc stdenv.glibc dwarf-fortress-unfuck SDL ];
  platform =
    if stdenv.system == "x86_64-linux" then "linux"
    else if stdenv.system == "i686-linux" then "linux32"
    else throw "Unsupported platform";
  sha256 =
    if stdenv.system == "x86_64-linux" then "18bjyhjp5458bfbizm8vq4s00pqpfs097qp6pv76m84kgbc4ghg3"
    else if stdenv.system == "i686-linux" then "1b9i4kf4c8s6bhqwn8jx100mg7fqp8nmswrai5w8dsma01py4amr"
    else throw "Unsupported platform";

in

assert dwarf-fortress-unfuck.dfVersion == dfVersion;

stdenv.mkDerivation {
  name = "dwarf-fortress-original-${dfVersion}";

  src = fetchurl {
    url = "http://www.bay12games.com/dwarves/df_${baseVersion}_${patchVersion}_${platform}.tar.bz2";
    inherit sha256;
  };

  installPhase = ''
    mkdir -p $out
    cp -r * $out
    rm $out/libs/lib*

    # Store the original hash
    md5sum $out/libs/Dwarf_Fortress | awk '{ print $1 }' > $out/hash.md5.orig

    patchelf \
      --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) \
      --set-rpath "${libpath}" \
      $out/libs/Dwarf_Fortress

    # Store the new hash
    md5sum $out/libs/Dwarf_Fortress | awk '{ print $1 }' > $out/hash.md5
  '';

  passthru = { inherit baseVersion patchVersion dfVersion; };

  meta = with stdenv.lib; {
    description = "A single-player fantasy game with a randomly generated adventure world";
    homepage = http://www.bay12games.com/dwarves;
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
    maintainers = with maintainers; [ a1russell robbinch roconnor the-kenny abbradar ];
  };
}
