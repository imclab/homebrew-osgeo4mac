require 'formula'

class GdalFilegdb < Formula
  homepage 'http://www.gdal.org/ogr/drv_filegdb.html'
  url 'http://download.osgeo.org/gdal/1.10.1/gdal-1.10.1.tar.gz'
  sha1 'b4df76e2c0854625d2bedce70cc1eaf4205594ae'

  depends_on "filegdb-api"
  depends_on 'gdal'

  def install
    filegdb_opt = Formula.factory('filegdb-api').opt_prefix
    (lib/'gdalplugins').mkpath

    # cxx flags
    args = %W[-Iport -Igcore -Iogr -Iogr/ogrsf_frmts
               -Iogr/ogrsf_frmts/filegdb -I#{filegdb_opt}/include/filegdb]

    # source files
    Dir['ogr/ogrsf_frmts/filegdb/*.c*'].each do |src|
      args.concat %W[#{src}]
    end

    # plugin dylib
    # TODO: can the compatibility_version be 1.10.0?
    args.concat %W[
      -dynamiclib
      -install_name #{HOMEBREW_PREFIX}/lib/gdalplugins/ogr_FileGDB.dylib
      -current_version #{version}
      -compatibility_version #{version}
      -o #{lib}/gdalplugins/ogr_FileGDB.dylib
      -undefined dynamic_lookup
    ]

    # ld flags
    args.concat %W[-L#{filegdb_opt}/lib -lFileGDBAPI]

    # build and install shared plugin
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      # fixes to make plugin work with gdal possibly built against libc++
      # NOTE: works, but I don't know if it is a sane fix
      # see: http://forums.arcgis.com/threads/95958-OS-X-Mavericks
      #      https://gist.github.com/jctull/f4d620cd5f1560577d17
      # TODO: needs removed as soon as ESRI updates filegdb binaries for libc++
      cxxstdlib_check :skip
      args.unshift "-mmacosx-version-min=10.8" # better than -stdlib=libstdc++ ?
    end
    system ENV.cxx, *args

  end

  def caveats; <<-EOS.undent
    This formula provides a plugin that allows GDAL or OGR to access geospatial
    data stored in its format. In order to use the shared plugin, you will need
    to set the following enviroment variable:

      export GDAL_DRIVER_PATH=#{HOMEBREW_PREFIX}/lib/gdalplugins

    ============================== IMPORTANT ==============================
    If compiled using clang (default) on 10.9+ this plugin was built against
    libstdc++ (like filegdb binaries), which may load into your GDAL, but
    possibly be incompatible. Please report any issues to:
        https://github.com/osgeo/homebrew-osgeo4mac/issues

    EOS
  end
end
