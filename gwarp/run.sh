#!/bin/bash

source ${ciop_job_include}

tsrs="`ciop-getparam tsrs`"

INPUTDIR=$TMPDIR/input
PROJDIR=$TMPDIR/proj
CROPDIR=$TMPDIR/crop
NDVIDIR=$TMPDIR/ndvi

mkdir -p $INPUTDIR $PROJDIR $CROPDIR $NDVIDIR

while read product
do

  ciop-log "INFO" "Getting product from $product"

  retrieved=`ciop-copy -U -o $INPUTDIR $product`

  ciop-log "DEBUG" "The local product is $retrieved"

  for band in 4 5 6
  do
  	tar tfz $retrieved | grep B$band.TIF | xargs tar -C $INPUTDIR -zxvf $retrieved 1>&2
  done  

  ciop-log "DEBUG" "`tree $TMPDIR`"

  for tif in `ls $INPUTDIR/*.TIF`
  do
    gdalwarp  -t_srs $tsrs $tif $PROJDIR/proj_`basename $tif` 1>&2
  done

ciop-log "DEBUG" "`tree $TMPDIR`"

  b4="`find $OUTPUTDIR -name "proj_*B4*.TIF"`"
  b5="`find $OUTPUTDIR -name "proj_*B5*.TIF"`"
  b6="`find $OUTPUTDIR -name "proj_*B6*.TIF"`"

  ciop-log "INFO" "$b4 $b5 $b6"
  gdal_calc.py -b1 $b4 -b2 $b5 --outfile=$NDVIDIR/ndvi.tif --calc="(b1-b2)/(b1+b2)"
  gdal_calc.py -b1 $b5 -b1 $b6 --outfile=$NDVIDIR/ndbi.tif --calc="(b1-b2)/(b1+b2)"


  ciop-publish -m $NDVIDIR/ndvi.tif
  ciop-publish -m $NDVIDIR/ndbi.tif

  rm -fr $OUTPUTDIR/* $INPUTDIR/* #$TMPDIR/output.vrt $TMPDIR/output.tiff $TMPDIR/*.jpeg
done

