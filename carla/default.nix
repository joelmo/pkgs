{ stdenv, fetchzip, pkgs, system }:

stdenv.mkDerivation rec {
  name = "carla-2.0";

  src = fetchzip {
    url = "https://github.com/falkTX/Carla/archive/master.zip";
    sha256 = "13sp36jyvdksxpz77ijddjdmdlhq9yvlb1z93p0nr7bpc4xp567q";
  };

  buildInputs = with pkgs; [ 
    wineWow
    pkgconfig 
    python3
    # pyliblo - does not exist
    # liblo - enable this if pyliblo exists
    libclthreads
    libclxclient
    ffmpeg
    fluidsynth
    mesa_glu
    libpng
    libsmf
    /* linuxsampler */
    ntk
    minixml
    zita-convolver
    zita-resampler

    vstsdk
    # optionals:
    gtk2        # lv2 gtk2 ui support
    gtk3        # lv2 gtk3 ui support
    /* pygtk       # NekoFilter UI */ 
    /* zlib        # extra native plugins */
    /* zynaddsubfx # ZynAddSubFX banks */
    
    /* windows.mingw_w64 */
    /* windows.mingw_w64_headers */

    makeWrapper
  ] ++ (with python34Packages; 
  [ wrapPython
    pyqt5
  ]);

  pyuic5 = "PYUIC5=${pkgs.python34Packages.pyqt5}/bin/pyuic5";

  phaseNames = [ "wrapBinContentsPython" ];

  buildPhase = ''
    sed -i source/Makefile.mk -e "s#CARLA_VESTIGE_HEADER = true##"
    rm -r source/includes/vestige
    ln -s ${pkgs.vstsdk} source/includes/vst2
    export ${pyuic5}
    export PREFIX=$out
    #echo "=== compiling win64 ==="
    #make win64 
    #echo "=== compiling wine64 ==="
    #make wine64
    #echo "=== compiling carla ==="
    make 
  '';

  installPhase = ''
    make ${pyuic5} install PREFIX=$out
    for i in $out/bin/*; do
      wrapProgram "$i" --set PYTHONPATH $PYTHONPATH
    done
    for i in $out/bin/.*wrapped; do
      sed -i $i \
        -e "s#python#${pkgs.python3}/bin/python3#"
    done

    for i in $out/share/carla/resources/{*-ui,*-plugin*}; do
      patch --batch $i ${./fixpypath.patch}
    done
  '';

  meta = with stdenv.lib; {
    description = "Audio plugin host";
    homepage = http://ardour.org/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.joelmo ];
  };
}
