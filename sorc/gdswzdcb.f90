 SUBROUTINE GDSWZDCB(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
                     XPTS,YPTS,RLON,RLAT,NRET, &
                     LROT,CROT,SROT,LMAP,XLON,XLAT,YLON,YLAT,AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCB   GDS WIZARD FOR ROTATED EQUIDISTANT CYLINDRICAL
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB 2 GRID DEFINITION
!           TEMPLATE (PASSED IN INTEGER FROM AS DECODED BY THE
!           NCEP G2 LIBRARY) AND RETURNS ONE OF THE FOLLOWING:
!             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
!             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
!           FOR ROTATED EQUIDISTANT CYLINDRICAL PROJECTIONS WITH
!           ARAKAWA "E" STAGGER.  THE SCAN MODE (SECTION 3, OCT 72,
!           BITS 5-6) DETERMINES WHETHER THIS IS AN "H" OR "V" GRID.
!           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
!           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
!           OUTPUT ELEMENTS ARE SET TO FILL VALUES.
!           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
!           OPTIONALLY, THE VECTOR ROTATIONS AND THE MAP JACOBIANS
!           FOR THIS GRID MAY BE RETURNED AS WELL.
!
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
!   97-10-20  IREDELL  INCLUDE MAP OPTIONS
!   98-08-19  BALDWIN  MODIFY GDSWZDC9 FOR TYPE 203 ETA GRIDS
! 2003-06-11  IREDELL  INCREASE PRECISION
! 2012-08-02  GAYNO    INCREASE XMAX SO ON-GRID POINTS ARE NOT
!                      TAGGED AS OFF-GRID.
! 2015-07-14  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAY
!                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAY.
!
! USAGE:    CALL GDSWZDCB(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
!                    XPTS,YPTS,RLON,RLAT,NRET, &
!                    LROT,CROT,SROT,LMAP,XLON,XLAT,YLON,YLAT,AREA)
!
!   INPUT ARGUMENT LIST:
!     IGDTNUM  - INTEGER GRID DEFINITION TEMPLATE NUMBER.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTMPL  - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY.
!                CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTLEN  - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IOPT     - INTEGER OPTION FLAG
!                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
!                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
!     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
!     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
!                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
!                (ACCEPTABLE RANGE: -360. TO 360.)
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
!                (ACCEPTABLE RANGE: -90. TO 90.)
!     LROT     - INTEGER FLAG TO RETURN VECTOR ROTATIONS IF 1
!     LMAP     - INTEGER FLAG TO RETURN MAP JACOBIANS IF 1
!
!   OUTPUT ARGUMENT LIST:
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT<0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT<0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT>0
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT>0
!     NRET     - INTEGER NUMBER OF VALID POINTS COMPUTED
!     CROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION COSINES IF LROT=1
!     SROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION SINES IF LROT=1
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!     XLON     - REAL (NPTS) DX/DLON IN 1/DEGREES IF LMAP=1
!     XLAT     - REAL (NPTS) DX/DLAT IN 1/DEGREES IF LMAP=1
!     YLON     - REAL (NPTS) DY/DLON IN 1/DEGREES IF LMAP=1
!     YLAT     - REAL (NPTS) DY/DLAT IN 1/DEGREES IF LMAP=1
!     AREA     - REAL (NPTS) AREA WEIGHTS IN M**2 IF LMAP=1
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,         PARAMETER     :: KD=SELECTED_REAL_KIND(15,45)
!
 INTEGER,         INTENT(IN   ) :: IGDTNUM, IGDTLEN
 INTEGER,         INTENT(IN   ) :: IGDTMPL(IGDTLEN)
 INTEGER,         INTENT(IN   ) :: IOPT
 INTEGER,         INTENT(IN   ) :: LROT, LMAP, NPTS
 INTEGER,         INTENT(  OUT) :: NRET
!
 REAL,            INTENT(IN   ) :: FILL
 REAL,            INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
 REAL,            INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
 REAL,            INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
 REAL,            INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
 REAL,            INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)
!
 REAL(KIND=KD),   PARAMETER     :: PI=3.14159265358979_KD
 REAL(KIND=KD),   PARAMETER     :: DPR=180._KD/PI
!
 INTEGER                        :: IM, JM, IS1, N, ISCALE
 INTEGER                        :: IROT, ISCAN, KSCAN
 INTEGER                        :: I_OFFSET_ODD, I_OFFSET_EVEN
!
 REAL(KIND=KD)                  :: RLAT0,RLON0
 REAL(KIND=KD)                  :: SLAT0,CLAT0
 REAL(KIND=KD)                  :: SLATR,CLATR,CLONR
 REAL(KIND=KD)                  :: RLATR,RLONR,DLATS,DLONS
 REAL(KIND=KD)                  :: SLAT,CLAT,CLON,SLON
 REAL                           :: DUM1,DUM2,HI,HS
 REAL(KIND=KD)                  :: RERTH,TERM1,TERM2
 REAL(KIND=KD)                  :: XLONF,XLATF,YLONF,YLATF
 REAL                           :: XMAX, XMIN, YMAX, YMIN, XPTF, YPTF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! IS THIS A ROTATED LAT/LON GRID?
 IF(IGDTNUM/=1)THEN
   CALL GDSWZDCB_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
   RETURN
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! IS THE EARTH RADIUS DEFINED?
 CALL EARTH_RADIUS(IGDTMPL,IGDTLEN,DUM1,DUM2)
 RERTH=DUM1
 IF(RERTH<0.)THEN
   CALL GDSWZDCB_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
   RETURN
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! ROUTINE ONLY WORKS FOR "E"-STAGGER GRIDS.
!   "V" GRID WHEN BIT 5 IS '1' AND BIT 6 IS '0'.
!   "H" GRID WHEN BIT 5 IS '0' AND BIT 6 IS '1'.
 I_OFFSET_ODD=MOD(IGDTMPL(19)/8,2)
 I_OFFSET_EVEN=MOD(IGDTMPL(19)/4,2)
 IF(I_OFFSET_ODD==I_OFFSET_EVEN) THEN
   CALL GDSWZDCB_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
   RETURN
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 ISCALE=IGDTMPL(10)*IGDTMPL(11)
 IF(ISCALE==0) ISCALE=1E6
 RLAT0=FLOAT(IGDTMPL(20))/FLOAT(ISCALE)
 RLAT0=RLAT0+90.0_KD
 RLON0=FLOAT(IGDTMPL(21))/FLOAT(ISCALE)
 IROT=MOD(IGDTMPL(14)/8,2)
 IM=IGDTMPL(8)*2-1
 JM=IGDTMPL(9)
 KSCAN=I_OFFSET_ODD
 ISCAN=MOD(IGDTMPL(19)/128,2)
 HI=(-1.)**ISCAN
 SLAT0=SIN(RLAT0/DPR)
 CLAT0=COS(RLAT0/DPR)
 DLATS=FLOAT(IGDTMPL(18))/FLOAT(ISCALE)
 DLONS=FLOAT(IGDTMPL(17))/FLOAT(ISCALE)
! THE GRIB2 CONVENTION FOR "I" RESOLUTION IS TWICE WHAT THIS ROUTINE ASSUMES.
 DLONS=DLONS*0.5_KD
 IF(KSCAN.EQ.0) THEN
   IS1=(JM+1)/2
 ELSE
   IS1=JM/2
 ENDIF
 XMIN=0
 XMAX=IM+2
 YMIN=0
 YMAX=JM+1
 NRET=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE GRID COORDINATES TO EARTH COORDINATES
 IF(IOPT.EQ.0.OR.IOPT.EQ.1) THEN
   DO N=1,NPTS
     XPTF=YPTS(N)+(XPTS(N)-IS1)
     YPTF=YPTS(N)-(XPTS(N)-IS1)+KSCAN
     IF(XPTF.GE.XMIN.AND.XPTF.LE.XMAX.AND. &
        YPTF.GE.YMIN.AND.YPTF.LE.YMAX) THEN
       HS=HI*SIGN(1.,XPTF-(IM+1)/2)
       RLONR=(XPTF-(IM+1)/2)*DLONS
       RLATR=(YPTF-(JM+1)/2)*DLATS
       CLONR=COS(RLONR/DPR)
       SLATR=SIN(RLATR/DPR)
       CLATR=COS(RLATR/DPR)
       SLAT=CLAT0*SLATR+SLAT0*CLATR*CLONR
       IF(SLAT.LE.-1) THEN
         CLAT=0.
         CLON=COS(RLON0/DPR)
         RLON(N)=0
         RLAT(N)=-90
       ELSEIF(SLAT.GE.1) THEN
         CLAT=0.
         CLON=COS(RLON0/DPR)
         RLON(N)=0
         RLAT(N)=90
       ELSE
         CLAT=SQRT(1-SLAT**2)
         CLON=(CLAT0*CLATR*CLONR-SLAT0*SLATR)/CLAT
         CLON=MIN(MAX(CLON,-1._KD),1._KD)
         RLON(N)=MOD(RLON0+HS*DPR*ACOS(CLON)+3600,360._KD)
         RLAT(N)=DPR*ASIN(SLAT)
       ENDIF
       NRET=NRET+1
       IF(LROT.EQ.1) THEN
         IF(IROT.EQ.1) THEN
           IF(CLATR.LE.0) THEN
             CROT(N)=-SIGN(1._KD,SLATR*SLAT0)
             SROT(N)=0
           ELSE
             SLON=SIN((RLON(N)-RLON0)/DPR)
             CROT(N)=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
             SROT(N)=SLAT0*SLON/CLATR
           ENDIF
         ELSE
           CROT(N)=1
           SROT(N)=0
         ENDIF
       ENDIF
       IF(LMAP.EQ.1) THEN
         IF(CLATR.LE.0) THEN
           XLON(N)=FILL
           XLAT(N)=FILL
           YLON(N)=FILL
           YLAT(N)=FILL
           AREA(N)=FILL
         ELSE
           SLON=SIN((RLON(N)-RLON0)/DPR)
           TERM1=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
           TERM2=SLAT0*SLON/CLATR
           XLONF=TERM1*CLAT/(DLONS*CLATR)
           XLATF=-TERM2/(DLONS*CLATR)
           YLONF=TERM2*CLAT/DLATS
           YLATF=TERM1/DLATS
           XLON(N)=XLONF-YLONF
           XLAT(N)=XLATF-YLATF
           YLON(N)=XLONF+YLONF
           YLAT(N)=XLATF+YLATF
           AREA(N)=RERTH**2*CLATR*DLATS*DLONS*2/DPR**2
         ENDIF
       ENDIF
     ELSE
       RLON(N)=FILL
       RLAT(N)=FILL
     ENDIF
   ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE EARTH COORDINATES TO GRID COORDINATES
 ELSEIF(IOPT.EQ.-1) THEN
   DO N=1,NPTS
     IF(ABS(RLON(N)).LE.360.AND.ABS(RLAT(N)).LE.90) THEN
       HS=SIGN(1._KD,MOD(RLON(N)-RLON0+180+3600,360._KD)-180)
       CLON=COS((RLON(N)-RLON0)/DPR)
       SLAT=SIN(RLAT(N)/DPR)
       CLAT=COS(RLAT(N)/DPR)
       SLATR=CLAT0*SLAT-SLAT0*CLAT*CLON
       IF(SLATR.LE.-1) THEN
         CLATR=0.
         RLONR=0
         RLATR=-90
       ELSEIF(SLATR.GE.1) THEN
         CLATR=0.
         RLONR=0
         RLATR=90
       ELSE
         CLATR=SQRT(1-SLATR**2)
         CLONR=(CLAT0*CLAT*CLON+SLAT0*SLAT)/CLATR
         CLONR=MIN(MAX(CLONR,-1._KD),1._KD)
         RLONR=HS*DPR*ACOS(CLONR)
         RLATR=DPR*ASIN(SLATR)
       ENDIF
       XPTF=(IM+1)/2+RLONR/DLONS
       YPTF=(JM+1)/2+RLATR/DLATS
       IF(XPTF.GE.XMIN.AND.XPTF.LE.XMAX.AND. &
          YPTF.GE.YMIN.AND.YPTF.LE.YMAX) THEN
         XPTS(N)=IS1+(XPTF-(YPTF-KSCAN))/2
         YPTS(N)=(XPTF+(YPTF-KSCAN))/2
         NRET=NRET+1
         IF(LROT.EQ.1) THEN
           IF(IROT.EQ.1) THEN
             IF(CLATR.LE.0) THEN
               CROT(N)=-SIGN(1._KD,SLATR*SLAT0)
               SROT(N)=0
             ELSE
               SLON=SIN((RLON(N)-RLON0)/DPR)
               CROT(N)=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
               SROT(N)=SLAT0*SLON/CLATR
             ENDIF
           ELSE
             CROT(N)=1
             SROT(N)=0
           ENDIF
         ENDIF
         IF(LMAP.EQ.1) THEN
           IF(CLATR.LE.0) THEN
             XLON(N)=FILL
             XLAT(N)=FILL
             YLON(N)=FILL
             YLAT(N)=FILL
             AREA(N)=FILL
           ELSE
             SLON=SIN((RLON(N)-RLON0)/DPR)
             TERM1=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
             TERM2=SLAT0*SLON/CLATR
             XLONF=TERM1*CLAT/(DLONS*CLATR)
             XLATF=-TERM2/(DLONS*CLATR)
             YLONF=TERM2*CLAT/DLATS
             YLATF=TERM1/DLATS
             XLON(N)=XLONF-YLONF
             XLAT(N)=XLATF-YLATF
             YLON(N)=XLONF+YLONF
             YLAT(N)=XLATF+YLATF
             AREA(N)=RERTH**2*CLATR*DLATS*DLONS*2/DPR**2
           ENDIF
         ENDIF
       ELSE
         XPTS(N)=FILL
         YPTS(N)=FILL
       ENDIF
     ELSE
       XPTS(N)=FILL
       YPTS(N)=FILL
     ENDIF
   ENDDO
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE GDSWZDCB
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 SUBROUTINE GDSWZDCB_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCB_ERROR   GDSWZDCB ERROR HANDLER
!   PRGMMR: GAYNO       ORG: W/NMC23       DATE: 2015-07-13
!
! ABSTRACT: UPON AN ERROR, THIS SUBPROGRAM ASSIGNS
!           A "FILL" VALUE TO THE OUTPUT FIELDS.

! PROGRAM HISTORY LOG:
! 2015-07-13  GAYNO     INITIAL VERSION
!
! USAGE:    CALL GDSWZDCB_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
!
!   INPUT ARGUMENT LIST:
!     IOPT     - INTEGER OPTION FLAG
!                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
!                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
!     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
!     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
!                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
!   OUTPUT ARGUMENT LIST:
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER, INTENT(IN   ) :: IOPT, NPTS
!
 REAL,    INTENT(IN   ) :: FILL
 REAL,    INTENT(  OUT) :: RLAT(NPTS),RLON(NPTS)
 REAL,    INTENT(  OUT) :: XPTS(NPTS),YPTS(NPTS)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(IOPT>=0) THEN
   RLON=FILL
   RLAT=FILL
 ENDIF
 IF(IOPT<=0) THEN
   XPTS=FILL
   YPTS=FILL
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE GDSWZDCB_ERROR
