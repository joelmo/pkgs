{ stdenv, pkgs }:

# TODO:
# - Wine should use ASIO for audio, see audio tab in winecfg.
#   To switch audio to ASIO edit registry HKEY_CURRENT_USER\Software\Wine\Drivers,
#   Add entry 'Audio=alsa'.
# - Wine can't find wineasio.dll.so, users need to put this in $wine/lib/wine
#   but users should not have to do this. Need to run wine64 regsvc32 wineasio.dll.so

let 
  wine = pkgs.wineWow;
  wine32 = pkgs.wine32;
  system = pkgs.system;
in
stdenv.mkDerivation rec {
  name = "wineasio-0.9.2";
  src = pkgs.fetchurl {
      url = "mirror://sourceforge/wineasio/${name}.tar.gz";
      sha256 = "02xgj9yr03yqy600m93ds4j491kwi0mxigjq0pf0ghyflh82vg4z";
  };
  buildInputs = with pkgs; [ ed wine asiosdk libjack2 gcc_multi ];
  buildPhase = ''
    cp ${pkgs.asiosdk}/common/asio.h .
    cp asio.h asio.h.i686
    chmod +w asio.h
    ./prepare_64bit_asio
    ln -s ${wine}/include/wine .
    export PREFIX=${wine}
    export CFLAGS="$NIX_CFLAGS_COMPILE"
    echo "MAKE 11111111111"
    make -f Makefile64 PREFIX=${wine}
    mv wineasio.dll.so wineasio.dll.so.x86_64
    cp asio.h.i686 asio.h
    make clean
# TODO: need multilib "lib32-jack"
    #echo "MAKE 222222222"
    #make PREFIX=${wine} LDFLAGS=$NIX_LD_FLAGS WINECC=${wine32}/bin/winegcc
  '';
  installPhase = ''
    name=wineasio
    install -D -m755 $name.dll.so.x86_64 $out/lib64/wine/$name.dll.so
    #install -D -m755 $name.dll.so $out/lib/wine/$name.dll.so
    install -D -m644 README $out/share/README
  '';
  meta = {
    description = "ASIO driver for WINE";
    license = stdenv.lib.licenses.lgpl21;
    homepage = http://sourceforge.net/projects/wineasio/;
    maintainers = with stdenv.lib.maintainers; [ joelmo ];
    hydraPlatforms = [];
  };
}
