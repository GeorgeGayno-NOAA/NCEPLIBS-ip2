 SUBROUTINE GDSWZD05(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
                     XPTS,YPTS,RLON,RLAT,NRET, &
                     LROT,CROT,SROT,LMAP,XLON,XLAT,YLON,YLAT,AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD05   GDS WIZARD FOR POLAR STEREOGRAPHIC AZIMUTHAL
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB 2 GRID DEFINITION
!           TEMPLATE (PASSED IN INTEGER FROM AS DECODED BY THE
!           NCEP G2 LIBRARY) AND RETURNS ONE OF THE FOLLOWING:
!             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
!             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
!           FOR POLAR STEREOGRAPHIC AZIMUTHAL PROJECTIONS.
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
!   09-05-13  GAYNO    ENSURE AREA ALWAYS POSITIVE
! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAY
!                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAY.
!
! USAGE:    CALL GDSWZD05(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
!                     XPTS,YPTS,RLON,RLAT,NRET, &
!                     LROT,CROT,SROT,LMAP,XLON,XLAT,YLON,YLAT,AREA)
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
!                (PROPORTIONAL TO THE SQUARE OF THE MAP FACTOR)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,          INTENT(IN   ) :: IGDTNUM, IGDTLEN
 INTEGER,          INTENT(IN   ) :: IGDTMPL(IGDTLEN)
 INTEGER,          INTENT(IN   ) :: IOPT
 INTEGER,          INTENT(IN   ) :: LMAP, LROT, NPTS
 INTEGER,          INTENT(  OUT) :: NRET
!
 REAL,             INTENT(IN   ) :: FILL
 REAL,             INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
 REAL,             INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
 REAL,             INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
 REAL,             INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
 REAL,             INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)
!
 REAL,             PARAMETER     :: PI=3.14159265358979
 REAL,             PARAMETER     :: DPR=180./PI
 REAL,             PARAMETER     :: PI2=PI/2.0
 REAL,             PARAMETER     :: PI4=PI/4.0
!
 INTEGER                         :: IM, JM, IPROJ, IROT
 INTEGER                         :: ISCAN, JSCAN, N, ITER
!
 LOGICAL                         :: ELLIPTICAL
!
 REAL                            :: ALAT, ALAT1, ALONG, MC, DIFF 
 REAL                            :: E, E_OVER_2, T, TC, RHO
 REAL                            :: CLAT, DI, DJ, DE, DE2
 REAL                            :: DX, DY, DXS, DYS
 REAL                            :: DR, DR2, H, HI, HJ
 REAL                            :: ORIENT, RLAT1, RLON1, RERTH, E2
 REAL                            :: XMAX, XMIN, YMAX, YMIN
 REAL                            :: SLAT, SLATR, XP, YP
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! IS THIS A POLAR STEREOGRAPHIC GRID?
 IF(IGDTNUM/=20)THEN
   CALL GDSWZD05_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
   RETURN
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 CALL EARTH_RADIUS(IGDTMPL,IGDTLEN,RERTH,E2)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! IS THE EARTH RADIUS AND ECCENTICITY DEFINED?
 IF(RERTH<0..OR.E2<0.0) THEN
   CALL GDSWZD05_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
   RETURN
 ENDIF
 ELLIPTICAL=.FALSE.  ! ELLIPTICAL EARTH
 IF(E2>0.0)ELLIPTICAL=.TRUE.
 IM=IGDTMPL(8)
 JM=IGDTMPL(9)
 RLAT1=FLOAT(IGDTMPL(10))*1.E-6
 RLON1=FLOAT(IGDTMPL(11))*1.E-6
 IROT=MOD(IGDTMPL(12)/8,2)
 SLAT=FLOAT(ABS(IGDTMPL(13)))*1.E-6
 SLATR=SLAT/DPR
 ORIENT=FLOAT(IGDTMPL(14))*1.E-6
 DX=FLOAT(IGDTMPL(15))*1.E-3
 DY=FLOAT(IGDTMPL(16))*1.E-3
 IPROJ=MOD(IGDTMPL(17)/128,2)
 ISCAN=MOD(IGDTMPL(18)/128,2)
 JSCAN=MOD(IGDTMPL(18)/64,2)
 H=(-1.)**IPROJ
 HI=(-1.)**ISCAN
 HJ=(-1.)**(1-JSCAN)
 DXS=DX*HI
 DYS=DY*HJ
!
! FIND X/Y OF POLE
 IF (.NOT.ELLIPTICAL) THEN
   DE=(1.+SIN(SLAT/DPR))*RERTH
   DR=DE*COS(RLAT1/DPR)/(1+H*SIN(RLAT1/DPR))
   XP=1-H*SIN((RLON1-ORIENT)/DPR)*DR/DXS
   YP=1+COS((RLON1-ORIENT)/DPR)*DR/DYS
   DE2=DE**2
 ELSE  ! ELLIPTICAL
   E=SQRT(E2)
   E_OVER_2=E*0.5
   ALAT=H*RLAT1/DPR
   ALONG = (RLON1-ORIENT)/DPR
   T=TAN(PI4-ALAT/2.)/((1.-E*SIN(ALAT))/  &
     (1.+E*SIN(ALAT)))**(E_OVER_2)
   TC=TAN(PI4-SLATR/2.)/((1.-E*SIN(SLATR))/  &
     (1.+E*SIN(SLATR)))**(E_OVER_2)
   MC=COS(SLATR)/SQRT(1.0-E2*(SIN(SLATR)**2))
   RHO=RERTH*MC*T/TC
   YP = 1.0 + RHO*COS(H*ALONG)/DYS
   XP = 1.0 - RHO*SIN(H*ALONG)/DXS
 ENDIF ! ELLIPTICAL?
 XMIN=0
 XMAX=IM+1
 YMIN=0
 YMAX=JM+1
 NRET=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE GRID COORDINATES TO EARTH COORDINATES
 IF(IOPT.EQ.0.OR.IOPT.EQ.1) THEN
   IF(.NOT.ELLIPTICAL)THEN
   DO N=1,NPTS
     IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
        YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
       DI=(XPTS(N)-XP)*DXS
       DJ=(YPTS(N)-YP)*DYS
       DR2=DI**2+DJ**2
       IF(DR2.LT.DE2*1.E-6) THEN
         RLON(N)=0.
         RLAT(N)=H*90.
       ELSE
         RLON(N)=MOD(ORIENT+H*DPR*ATAN2(DI,-DJ)+3600,360.)
         RLAT(N)=H*DPR*ASIN((DE2-DR2)/(DE2+DR2))
       ENDIF
       NRET=NRET+1
       IF(LROT.EQ.1) THEN
         IF(IROT.EQ.1) THEN
           CROT(N)=H*COS((RLON(N)-ORIENT)/DPR)
           SROT(N)=SIN((RLON(N)-ORIENT)/DPR)
         ELSE
           CROT(N)=1
           SROT(N)=0
         ENDIF
       ENDIF
       IF(LMAP.EQ.1) THEN
         IF(DR2.LT.DE2*1.E-6) THEN
           XLON(N)=0.
           XLAT(N)=-SIN((RLON(N)-ORIENT)/DPR)/DPR*DE/DXS/2
           YLON(N)=0.
           YLAT(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DE/DYS/2
           AREA(N)=RERTH**2*ABS(DXS)*ABS(DYS)*4/DE2
         ELSE
           DR=SQRT(DR2)
           CLAT=COS(RLAT(N)/DPR)
           XLON(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DR/DXS
           XLAT(N)=-SIN((RLON(N)-ORIENT)/DPR)/DPR*DR/DXS/CLAT
           YLON(N)=SIN((RLON(N)-ORIENT)/DPR)/DPR*DR/DYS
           YLAT(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DR/DYS/CLAT
           AREA(N)=RERTH**2*CLAT**2*ABS(DXS)*ABS(DYS)/DR2
         ENDIF
       ENDIF
     ELSE
       RLON(N)=FILL
       RLAT(N)=FILL
     ENDIF
   ENDDO
   ELSE  !ELLIPTICAL
      DO N=1,NPTS
         IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND.  &
            YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
           DI=(XPTS(N)-XP)*DXS
           DJ=(YPTS(N)-YP)*DYS
           RHO=SQRT(DI*DI+DJ*DJ)
           T=(RHO*TC)/(RERTH*MC)
           IF(ABS(YPTS(N)-YP)<0.01)THEN
             IF(DI>0.0) ALONG=ORIENT+H*90.0
             IF(DI<=0.0) ALONG=ORIENT-H*90.0
           ELSE
             ALONG=ORIENT+H*ATAN(DI/(-DJ))*DPR
             IF(DJ>0) ALONG=ALONG+180.
           END IF
           ALAT1=PI2-2.0*ATAN(T)
           DO ITER=1,10
             ALAT = PI2 - 2.0*ATAN(T*(((1.0-E*SIN(ALAT1))/  &
                   (1.0+E*SIN(ALAT1)))**(E_OVER_2)))
             DIFF = ABS(ALAT-ALAT1)*DPR
             IF (DIFF < 0.000001) EXIT
             ALAT1=ALAT
           ENDDO
           RLAT(N)=H*ALAT*DPR
           RLON(N)=ALONG
           IF(RLON(N)<0.0) RLON(N)=RLON(N)+360.
           IF(RLON(N)>360.0) RLON(N)=RLON(N)-360.0
           NRET=NRET+1
         ELSE
           RLON(N)=FILL
           RLAT(N)=FILL
         ENDIF
       ENDDO
     ENDIF ! ELLIPTICAL
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE EARTH COORDINATES TO GRID COORDINATES
 ELSEIF(IOPT.EQ.-1) THEN
     IF(.NOT.ELLIPTICAL)THEN
   DO N=1,NPTS
     IF(ABS(RLON(N)).LE.360.AND.ABS(RLAT(N)).LE.90.AND. &
                                   H*RLAT(N).NE.-90) THEN
       DR=DE*TAN((90-H*RLAT(N))/2/DPR)
       XPTS(N)=XP+H*SIN((RLON(N)-ORIENT)/DPR)*DR/DXS
       YPTS(N)=YP-COS((RLON(N)-ORIENT)/DPR)*DR/DYS
       IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
          YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
         NRET=NRET+1
         IF(LROT.EQ.1) THEN
           IF(IROT.EQ.1) THEN
             CROT(N)=H*COS((RLON(N)-ORIENT)/DPR)
             SROT(N)=SIN((RLON(N)-ORIENT)/DPR)
           ELSE
             CROT(N)=1
             SROT(N)=0
           ENDIF
         ENDIF
         IF(LMAP.EQ.1) THEN
           DR2=DR**2
           IF(DR2.LT.DE2*1.E-6) THEN
             XLON(N)=0.
             XLAT(N)=-SIN((RLON(N)-ORIENT)/DPR)/DPR*DE/DXS/2
             YLON(N)=0.
             YLAT(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DE/DYS/2
             AREA(N)=RERTH**2*ABS(DXS)*ABS(DYS)*4/DE2
           ELSE
             CLAT=COS(RLAT(N)/DPR)
             XLON(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DR/DXS
             XLAT(N)=-SIN((RLON(N)-ORIENT)/DPR)/DPR*DR/DXS/CLAT
             YLON(N)=SIN((RLON(N)-ORIENT)/DPR)/DPR*DR/DYS
             YLAT(N)=H*COS((RLON(N)-ORIENT)/DPR)/DPR*DR/DYS/CLAT
             AREA(N)=RERTH**2*CLAT**2*ABS(DXS)*ABS(DYS)/DR2
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
     ELSE ! ELLIPTICAL CALCS
       DO N=1,NPTS
         IF(ABS(RLON(N)).LE.360.AND.ABS(RLAT(N)).LE.90.AND.  &
                                        H*RLAT(N).NE.-90) THEN
           ALAT = H*RLAT(N)/DPR
           ALONG = (RLON(N)-ORIENT)/DPR
           T=TAN(PI4-ALAT*0.5)/((1.-E*SIN(ALAT))/  &
             (1.+E*SIN(ALAT)))**(E_OVER_2)
           RHO=RERTH*MC*T/TC
           XPTS(N)= XP + RHO*SIN(H*ALONG) / DXS
           YPTS(N)= YP - RHO*COS(H*ALONG) / DYS
           IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND.  &
              YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
             NRET=NRET+1
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
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE GDSWZD05
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 SUBROUTINE GDSWZD05_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD05_ERROR   GDSWZD05 ERROR HANDLER
!   PRGMMR: GAYNO       ORG: W/NMC23       DATE: 2015-07-13
!
! ABSTRACT: UPON AN ERROR, THIS SUBPROGRAM ASSIGNS
!           A "FILL" VALUE TO THE OUTPUT FIELDS.

! PROGRAM HISTORY LOG:
! 2015-07-13  GAYNO     INITIAL VERSION
!
! USAGE:    CALL GDSWZD05_ERROR(IOPT,FILL,RLAT,RLON,XPTS,YPTS,NPTS)
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
 END SUBROUTINE GDSWZD05_ERROR
