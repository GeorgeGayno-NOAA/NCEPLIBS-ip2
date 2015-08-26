 SUBROUTINE IPOLATEV(IP,IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                     IGDTNUMO,IGDTMPLO,IGDTLENO, &
                     MI,MO,KM,IBI,LI,UI,VI, &
                     NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  IPOLATEV   IREDELL'S POLATE FOR VECTOR FIELDS
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM INTERPOLATES VECTOR FIELDS
!           FROM ANY GRID TO ANY GRID (JOE IRWIN'S DREAM).
!           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
!           THE FOLLOWING INTERPOLATION METHODS ARE POSSIBLE:
!             (IP=0) BILINEAR
!             (IP=1) BICUBIC
!             (IP=2) NEIGHBOR
!             (IP=3) BUDGET
!             (IP=4) SPECTRAL
!             (IP=6) NEIGHBOR-BUDGET
!           SOME OF THESE METHODS HAVE INTERPOLATION OPTIONS AND/OR
!           RESTRICTIONS ON THE INPUT OR OUTPUT GRIDS, BOTH OF WHICH
!           ARE DOCUMENTED MORE FULLY IN THEIR RESPECTIVE SUBPROGRAMS.
!
!           THE INPUT AND OUTPUT GRIDS ARE DEFINED BY THEIR GRIB 2 GRID
!           DEFINITION TEMPLATE AS DECODED BY THE NCEP G2 LIBRARY.  THE
!           CODE RECOGNIZES THE FOLLOWING PROJECTIONS, WHERE
!           "IGDTNUMI/O" IS THE GRIB 2 GRID DEFINTION TEMPLATE NUMBER
!           FOR THE INPUT AND OUTPUT GRIDS, RESPECTIVELY:
!             (IGDTNUMI/O=00) EQUIDISTANT CYLINDRICAL
!             (IGDTNUMI/O=01) ROTATED EQUIDISTANT CYLINDRICAL. "E" AND
!                             NON-"E" STAGGERED
!             (IGDTNUMI/O=10) MERCATOR CYLINDRICAL
!             (IGDTNUMI/O=20) POLAR STEREOGRAPHIC AZIMUTHAL
!             (IGDTNUMI/O=30) LAMBERT CONFORMAL CONICAL
!             (IGDTNUMI/O=40) GAUSSIAN CYLINDRICAL
!
!           THE INPUT AND OUTPUT VECTORS ARE ROTATED SO THAT THEY ARE
!           EITHER RESOLVED RELATIVE TO THE DEFINED GRID
!           IN THE DIRECTION OF INCREASING X AND Y COORDINATES
!           OR RESOLVED RELATIVE TO EASTERLY AND NORTHERLY DIRECTIONS,
!           AS DESIGNATED BY THEIR RESPECTIVE GRID DEFINITION SECTIONS.
!
!           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
!           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED
!           ALONG WITH THEIR VECTOR ROTATION PARAMETERS.
!           ON THE OTHER HAND, THE DATA MAY BE INTERPOLATED TO A SET OF
!           STATION POINTS IF IGDTNUMO<0 (IGDTNUMO-255 FOR THE BUDGET OPTION),
!           IN WHICH CASE THE NUMBER OF POINTS AND THEIR LATITUDES AND
!           LONGITUDES MUST BE INPUT ALONG WITH THEIR VECTOR ROTATION 
!           PARAMETERS.
!
!           INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
!           OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
!           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
!           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
!        
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
! 2003-06-23  IREDELL  STAGGERING FOR GRID TYPE 203
! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAYS
!                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAYS.
!
! USAGE:    CALL IPOLATEV(IP,IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
!                         IGDTNUMO,IGDTMPLO,IGDTLENO, &
!                         MI,MO,KM,IBI,LI,UI,VI, &
!                         NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
!
!   INPUT ARGUMENT LIST:
!     IP       - INTEGER INTERPOLATION METHOD
!                (IP=0 FOR BILINEAR;
!                 IP=1 FOR BICUBIC;
!                 IP=2 FOR NEIGHBOR;
!                 IP=3 FOR BUDGET;
!                 IP=4 FOR SPECTRAL;
!                 IP=6 FOR NEIGHBOR-BUDGET)
!     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
!                (IP=0: MIN MASK %
!                 IP=1: CONSTRAINT OPTION, MIN MASK %
!                 IP=2: SEARCH RADIUS
!                 IP=3: NUMBER IN RADIUS, RADIUS WEIGHTS, MIN MASK %
!                 IP=4: SPECTRAL SHAPE, SPECTRAL TRUNCATION
!                 IP=6: NUMBER IN RADIUS, RADIUS WEIGHTS, MIN MASK %
!     IGDTNUMI - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTMPLI - INTEGER (IGDTLENI) GRID DEFINITION TEMPLATE ARRAY -
!                INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE. IGDTNUMO<0
!                MEANS INTERPOLATE TO RANDOM STATION POINTS.
!     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
!                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
!     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
!     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
!     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
!     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF RESPECTIVE IBI(K)=1)
!     UI       - REAL (MI,KM) INPUT U-COMPONENT FIELDS TO INTERPOLATE
!     VI       - REAL (MI,KM) INPUT V-COMPONENT FIELDS TO INTERPOLATE
!     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO<0)
!     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO<0)
!     CROT     - REAL (MO) VECTOR ROTATION COSINES (IF IGDTNUMO<0)
!     SROT     - REAL (MO) VECTOR ROTATION SINES (IF IGDTNUMO<0)
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!
!   OUTPUT ARGUMENT LIST:
!     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF IGDTNUMO>=0)
!     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO>=0)
!     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO>=0)
!     CROT     - REAL (MO) VECTOR ROTATION COSINES (IF IGDTNUMO>=0)
!     SROT     - REAL (MO) VECTOR ROTATION SINES (IF IGDTNUMO>=0)
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
!     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
!     UO       - REAL (MO,KM) OUTPUT U-COMPONENT FIELDS INTERPOLATED
!     VO       - REAL (MO,KM) OUTPUT V-COMPONENT FIELDS INTERPOLATED
!     IRET     - INTEGER RETURN CODE
!                0    SUCCESSFUL INTERPOLATION
!                1    UNRECOGNIZED INTERPOLATION METHOD
!                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
!                3    UNRECOGNIZED OUTPUT GRID
!                1X   INVALID BICUBIC METHOD PARAMETERS
!                3X   INVALID BUDGET METHOD PARAMETERS
!                4X   INVALID SPECTRAL METHOD PARAMETERS
!
! SUBPROGRAMS CALLED:
!   POLATEV0     INTERPOLATE VECTOR FIELDS (BILINEAR)
!   POLATEV1     INTERPOLATE VECTOR FIELDS (BICUBIC)
!   POLATEV2     INTERPOLATE VECTOR FIELDS (NEIGHBOR)
!   POLATEV3     INTERPOLATE VECTOR FIELDS (BUDGET)
!   POLATEV4     INTERPOLATE VECTOR FIELDS (SPECTRAL)
!   POLATEV6     INTERPOLATE VECTOR FIELDS (NEIGHBOR-BUDGET)
!
! REMARKS: EXAMPLES DEMONSTRATING RELATIVE CPU COSTS.
!   THIS EXAMPLE IS INTERPOLATING 12 LEVELS OF WINDS
!   FROM THE 360 X 181 GLOBAL GRID (NCEP GRID 3)
!   TO THE 93 X 68 HAWAIIAN MERCATOR GRID (NCEP GRID 204).
!   THE EXAMPLE TIMES ARE FOR THE C90.  AS A REFERENCE, THE CP TIME
!   FOR UNPACKING THE GLOBAL 12 PAIRS OF WIND FIELDS IS 0.07 SECONDS.
!
!   BILINEAR    0                   0.05
!   BICUBIC     1   0               0.16
!   BICUBIC     1   1               0.17
!   NEIGHBOR    2                   0.02
!   BUDGET      3   -1,-1           0.94
!   SPECTRAL    4   0,40            0.31
!   SPECTRAL    4   1,40            0.33
!   SPECTRAL    4   0,-1            0.59
!   N-BUDGET    6   0,-1            0.31
!
!   THE SPECTRAL INTERPOLATION IS FAST FOR THE MERCATOR GRID.
!   HOWEVER, FOR SOME GRIDS THE SPECTRAL INTERPOLATION IS SLOW.
!   THE FOLLOWING EXAMPLE IS INTERPOLATING 12 LEVELS OF WINDS
!   FROM THE 360 X 181 GLOBAL GRID (NCEP GRID 3)
!   TO THE 93 X 65 CONUS LAMBERT CONFORMAL GRID (NCEP GRID 211).
!
!   METHOD      IP  IPOPT          CP SECONDS
!   --------    --  -------------  ----------
!   BILINEAR    0                   0.05
!   BICUBIC     1   0               0.15
!   BICUBIC     1   1               0.16
!   NEIGHBOR    2                   0.02
!   BUDGET      3   -1,-1           0.92
!   SPECTRAL    4   0,40            4.51
!   SPECTRAL    4   1,40            5.77
!   SPECTRAL    4   0,-1           12.60
!   N-BUDGET    6   0,-1            0.33
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,               INTENT(IN   ) :: IP, IPOPT(20), IBI(KM)
 INTEGER,               INTENT(IN   ) :: KM, MI, MO
 INTEGER,               INTENT(IN   ) :: IGDTNUMI, IGDTLENI
 INTEGER,               INTENT(IN   ) :: IGDTMPLI(IGDTLENI)
 INTEGER,               INTENT(IN   ) :: IGDTNUMO, IGDTLENO
 INTEGER,               INTENT(IN   ) :: IGDTMPLO(IGDTLENO)
 INTEGER,               INTENT(  OUT) :: IBO(KM), IRET, NO
!
 LOGICAL*1,             INTENT(IN   ) :: LI(MI,KM)
 LOGICAL*1,             INTENT(  OUT) :: LO(MO,KM)
!
 REAL,                  INTENT(IN   ) :: UI(MI,KM),VI(MI,KM)
 REAL,                  INTENT(INOUT) :: CROT(MO),SROT(MO)
 REAL,                  INTENT(INOUT) :: RLAT(MO),RLON(MO)
 REAL,                  INTENT(  OUT) :: UO(MO,KM),VO(MO,KM)
!
 INTEGER                              :: K, N
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  BILINEAR INTERPOLATION
 IF(IP.EQ.0) THEN
   CALL POLATEV0(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  BICUBIC INTERPOLATION
 ELSEIF(IP.EQ.1) THEN
   CALL POLATEV1(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  NEIGHBOR INTERPOLATION
 ELSEIF(IP.EQ.2) THEN
   CALL POLATEV2(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  BUDGET INTERPOLATION
 ELSEIF(IP.EQ.3) THEN
   CALL POLATEV3(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SPECTRAL INTERPOLATION
 ELSEIF(IP.EQ.4) THEN
   CALL POLATEV4(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  NEIGHBOR-BUDGET INTERPOLATION
 ELSEIF(IP.EQ.6) THEN
   CALL POLATEV6(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                 IGDTNUMO,IGDTMPLO,IGDTLENO, &
                 MI,MO,KM,IBI,LI,UI,VI,&
                 NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  UNRECOGNIZED INTERPOLATION METHOD
 ELSE
   IF(IGDTNUMO.GE.0) NO=0
   DO K=1,KM
     IBO(K)=1
     DO N=1,NO
       LO(N,K)=.FALSE.
       UO(N,K)=0.
       VO(N,K)=0.
     ENDDO
   ENDDO
   IRET=1
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE IPOLATEV
