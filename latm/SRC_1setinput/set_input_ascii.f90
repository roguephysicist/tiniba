!#########################################################
! January, 2005
! 
!(Additions by Ben Wilson, August 7, 2003)
!
! Modified for calligraphic P.
! 
! THE FOLLOWING DESCRIPTION NEEDS TO BE UPDATED
! 
! To do:
! Include tolerance option to remove the contribution when the
! tolerance threshold is violated.
! 
! Purpose:
! 
! The sole purpose of this porgram is to create input files
! for my tetrahedron code tetra_method
! 
! Takes raw momentum matrix elements, and generates matrix
! elements for position, generalized derivative of position,
! and energy transitions.
! 
! Applies scissor shift to the energies
! 
! Creates input file for LATM code
! 
! Uses function position.f                                    
! Uses function genderiv.f                                   
! 
! Control file determines which spectrum integrand is
! calculated.
!                                                                 
! For each transition there is an output file for both the       
! derivative and generalized derivative.                         
! For the position file on each line there is the                
!   kpoint index, r^x, r^y, r^z                                  
! For the generalized derivative file the data is grouped like   
!   kpoint index, r^x;x, r^y;x, r^z;x                            
!   kpoint index, r^x;y, r^y;y, r^z;y                            
!   kpoint index, r^x;z, r^y;z, r^z;z                            
! 
!!!##############
PROGRAM set_input
!!!##############
  USE inparams, ONLY : checkCommandLineInputs
  USE inparams, ONLY : readParamFile, readSpectrumFile
  USE inparams, ONLY : nSpinor
  USE inparams, ONLY : paramFile, spectrumFile
  USE inparams, ONLY : debug
  USE arrays, ONLY : DP, DPC, nVal, nMax, nSym, kMax, scissor
  USE arrays, ONLY : energy_data_filename, energys_data_filename
  USE arrays, ONLY : pmn_data_filename, rmn_data_filename
  USE arrays, ONLY : der_data_filename, smn_data_filename
  USE arrays, ONLY : rhomm_data_filename
  USE arrays, ONLY : allocateArrays, deallocateArrays
  USE symmetryOperations, ONLY : initializeSymOps
  USE file_control, ONLY : openOutputDataFiles
  USE file_control, ONLY : closeOutputDataFiles
  USE file_control, ONLY : writeOutputDataFileHeaders
  USE arrays, ONLY : momMatElem, posMatElem, derMatElem, Delta, spiMatElem
  USE arrays, ONLY : GenDerCalPosition
!!! BMS/FN
  USE arrays, ONLY : calrho
  USE arrays, ONLY : calDelta
  USE arrays, ONLY : calMomMatElem, cal_data_filename
  !!!!!!!!!!
  USE arrays, ONLY : calPosMatElem
  USE arrays, ONLY : efe
  !!!!!!!!!!
!  USE arrays, ONLY : denMatElem, den_data_filename
  USE arrays, ONLY : curMatElem, cur_data_filename
  USE arrays, ONLY : layeredCalculation
  USE arrays, ONLY : ndotCalculation
  USE arrays, ONLY : spinCalculation
  USE arrays, ONLY : layeredInjectionCurrent
!  USE arrays, ONLY : microscopicDensityCalculation
!  USE arrays, ONLY : microscopicCurrentCalculation
!!! BMS/FN
  USE arrays, ONLY : energy, energys, band, readenergyfile, scissorenergies
  USE arrays, ONLY : oldStyleScissors
  USE functions, ONLY : position, genderiv
  USE functions, ONLY : GenDerCalPositionf
  USE integrands, ONLY : calculateintegrands
   USE functions, ONLY : calposition
  IMPLICIT NONE
  
  INTEGER :: i, ii, ij, iii, l
  INTEGER :: ik, iv, ic
  INTEGER :: vp,cp
  INTEGER :: io_status
  REAL(DP) :: matTemp(6)
  REAL(DP) :: matTemp3(3)
  COMPLEX (DPC) :: tmpm
  COMPLEX(DPC) :: ci
  REAL (DP) :: scissorFactor
  INTEGER :: checkflag
  
  LOGICAL :: writeoutMEdata   ! flag controlling whether matrix element output
  !                             is written or not. Much slower if outputting.
  !-------------------------------------------------------------------
  call system("rm -f endWELLpmn")
  writeoutMEdata = .false.
  oldStyleScissors = .false.
  IF (oldStyleScissors) THEN
     WRITE(*,*) 'Using Hughes and Sipe version of scissors correction'
  END IF
  
  CALL getarg(1,paramFile)
  CALL getarg(2,spectrumFile)
  
  
  CALL checkCommandLineInputs
  CALL readParamFile
  CALL readSpectrumFile

  ! Test opening and closing files
  IF (debug) WRITE(6,*) "Testing opening and closing files"
  CALL openOutputDataFiles
  CALL closeOutputDataFiles
  IF (debug) WRITE(6,*) "Testing opening and closing files succeeded"
  
!  write(*,*)"%%%%%%%%%%%%%%%%%%%%%%"

  OPEN(11, FILE=pmn_data_filename, STATUS='OLD', IOSTAT=io_status)
  IF (io_status /= 0) THEN
     WRITE(6,*) "Error occured trying to open:", pmn_data_filename
     WRITE(6,*) "Error status returned is:", io_status
     WRITE(6,*) "Stopping"
     STOP "Stopping: error with momentum matrix element file"
!  else
!     WRITE(6,*) "no problem opening:", pmn_data_filename
  END IF
  
!!!BMS
!  IF (nSpinor == 2) THEN
  INQUIRE(FILE=smn_data_filename, EXIST=spinCalculation)
  if ( spinCalculation) then
!     WRITE(*,*) "Found file ", TRIM(smn_data_filename), " => Performing spin calculation"
     OPEN(41, FILE=smn_data_filename)
!  ELSE
!     WRITE(6,*) "no smn_data_filename => no-spin calculation"
  END IF
!  END IF

  INQUIRE(FILE=cal_data_filename, EXIST=layeredCalculation)
  IF ( layeredCalculation ) THEN
!     WRITE(*,*) "Found file ", TRIM(cal_data_filename), " => Performing layer P calculation"
     OPEN(16, FILE=cal_data_filename,IOSTAT=io_status)
!  else
!     WRITE(6,*) "no cal_data_filename => no-caligraphic P calculation"
  END IF

  INQUIRE(FILE=cur_data_filename, EXIST=layeredInjectionCurrent)
  IF ( layeredInjectionCurrent ) THEN
!     WRITE(*,*) "Found file ", TRIM(cur_data_filename), " => Performing layer dotJ calculation"
     OPEN(17, FILE=cur_data_filename,IOSTAT=io_status)
!  else
!     WRITE(6,*) "no cur_data_filename => no-caligraphic dotJ calculation"
  END IF
  
  INQUIRE(FILE=rhomm_data_filename, EXIST=ndotCalculation)
  IF ( ndotCalculation ) THEN
!     WRITE(*,*) "Found file ", TRIM(rhomm_data_filename), " => Performing ndot layered calculation"
     OPEN(69, FILE=rhomm_data_filename,IOSTAT=io_status)
!  else
!     WRITE(6,*) "no rhomm_data_filename => no-ndot calculation"
  END IF
  
!!!
!     INQUIRE(FILE=den_data_filename,EXIST=microscopicDensityCalculation)
!     IF ( microscopicDensityCalculation ) THEN
!        OPEN(16, FILE=den_data_filename,IOSTAT=io_status)
!        IF (io_status /= 0) THEN
!           WRITE(6,*) "Error occured trying to open:", den_data_filename
!           WRITE(6,*) "Error status returned is:", io_status
!           WRITE(6,*) "Stopping"
!           STOP "Stopping: error with density matrix element file"
!        END IF
!     END IF
!!!
!     INQUIRE(FILE=cur_data_filename,EXIST=microscopicCurrentCalculation)
!     IF ( microscopicCurrentCalculation ) THEN
!        OPEN(17, FILE=cur_data_filename,IOSTAT=io_status)
!        IF (io_status /= 0) THEN
!           WRITE(6,*) "Error occured trying to open:", cur_data_filename
!           WRITE(6,*) "Error status returned is:", io_status
!           WRITE(6,*) "Stopping"
!           STOP "Stopping: error with current matrix element file"
!        END IF
!     END IF
!!!
!!!BMS
!  write(*,*)"%%%%%%%%%%%%%%%%%%%%%%"
  
  CALL allocateArrays
  CALL readenergyfile
  CALL scissorenergies
  
  IF (writeoutMEdata) THEN
     OPEN(12, FILE=rmn_data_filename, STATUS='UNKNOWN')
     OPEN(13, FILE=der_data_filename, STATUS='UNKNOWN')
  END IF
  
  ! Open additional files
  
  CALL openOutputDataFiles
  
  CALL initializeSymOps
  
  CALL writeOutputDataFileHeaders
  
  DO ik = 1, kMax
     IF ((ik<11).OR.(MOD(ik,50).EQ.0).OR.(ik.EQ.kMax)) THEN
        WRITE(6,*)'set_input ik= ',ik
     END IF
     
     ! Use unscissored band energies to calculate rmn
     band(1:nMax) = energy(ik,1:nMax)
     
     DO iv = 1, nMax
        !------------------------
        ! DO ic = 1, nMax
        !------------------------
        !   reduced input begin
        !------------------------
        DO ic = iv, nMax
           !---------------------
           ! reduced input end
           !---------------------
           READ(11,*) (matTemp(l), l=1,6)

101        FORMAT(2I3,6E15.7)
           momMatElem(1,iv,ic) = matTemp(1) + (0.0d0,1.0d0)*matTemp(2)
           momMatElem(2,iv,ic) = matTemp(3) + (0.0d0,1.0d0)*matTemp(4)
           momMatElem(3,iv,ic) = matTemp(5) + (0.0d0,1.0d0)*matTemp(6)

           ! reduced input begin
           IF (ic.NE.iv) THEN
              DO ii=1,3
                 momMatElem(ii,ic,iv) = CONJG(momMatElem(ii,iv,ic))
              END DO
           END IF
           ! reduced input end

!!!BMS     
!           IF (nSpinor==2) THEN
! calculates S_{cc'} only!
           IF ( spinCalculation ) THEN
              if( (iv .ge. nval+1).and.(ic .ge. nval+1) ) then 
                 READ(41, *) (matTemp(l), l=1,6)
                 spiMatElem(1,iv,ic) = matTemp(1) + (0.d0,1.d0)*matTemp(2)
                 spiMatElem(2,iv,ic) = matTemp(3) + (0.d0,1.d0)*matTemp(4)
                 spiMatElem(3,iv,ic) = matTemp(5) + (0.d0,1.d0)*matTemp(6)
                 IF (ic.NE.iv) THEN
                    DO ii=1,3
                       spiMatElem(ii,ic,iv) = CONJG(spiMatElem(ii,iv,ic))
                    END DO
                 END IF
              end if
           END IF
!!!BMS
     
!!!BMS
              IF ( ndotCalculation ) then
!!! rho_{mm} is only diagonal and real
!                 if (iv.eq.ic) then
!                    READ(69,*) matTemp(1)
!!! rho_{cc'} is complex (see arrays.f90)
                 if( (iv .ge. nval+1).and.(ic .ge. nval+1) ) then 
                    READ(69,*) matTemp(1),matTemp(2)
                    IF(io_status.NE.0) THEN
                       WRITE(*,*) "ERROR: Couldn't read matTemp: rhomm layered calculation. Stopping"
                       WRITE(*,*) "Error number ", io_status
                       STOP "COULD NOT READ matTemp for rhomm"
                    ELSE
!!! rho_{mm} is real
!                       calrho(iv) = matTemp(1)
!!! rho_{cc'} is complex (see arrays.f90)
                       calrho(iv,ic) = matTemp(1)+(0.d0,1.d0)*matTemp(2)
                       IF (ic.NE.iv) THEN
                          calrho(ic,iv) = CONJG(calrho(iv,ic))
                       END IF
                    END IF
                 end if !iv=ic
              END IF
!!! 
!!! FN
           IF ( layeredCalculation ) then
              READ(16,*) (matTemp(l),l=1,6)
              IF(io_status.NE.0) THEN
                 WRITE(*,*) "ERROR: Could not read matTemp for layered calculation. Stopping"
                 WRITE(*,*) "Error number ", io_status
                 STOP "COULD NOT READ matTemp"
              ELSE
                 calMomMatElem(1,iv,ic) = matTemp(1) + (0.0d0,1.0d0)*matTemp(2)
                 calMomMatElem(2,iv,ic) = matTemp(3) + (0.0d0,1.0d0)*matTemp(4)
                 calMomMatElem(3,iv,ic) = matTemp(5) + (0.0d0,1.0d0)*matTemp(6)
              END IF
              IF (ic.NE.iv) THEN
                 DO ii=1,3
                   calMomMatElem(ii,ic,iv) = CONJG(calMomMatElem(ii,iv,ic))
                 END DO
              END IF
           END IF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          !! Calculate the calPosMatElem matrix elements 
          !! despues de calcular los calMomMatElem 
           IF ( layeredCalculation ) then
              DO ii=1,3
                 calPosMatElem(ii,iv,ic) = calPosition(ii,iv,ic,ik)
                 calPosMatElem(ii,ic,iv) = conjg(calPosMatElem(ii,iv,ic))
              END DO
           end if
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! jl 


!!! 
!           IF ( microscopicDensityCalculation ) THEN
!              IF ( iv .EQ. ic ) THEN
!                 READ(16,*) (matTemp(l),l=1,2)
!                 denMatElem(iv) = matTemp(1) + (0.0d0,1.0d0)*matTemp(2)
!              END IF
!           END IF
!!!     
        IF ( layeredInjectionCurrent ) THEN
           if ( iv .eq. ic ) then
              READ(17,*) (matTemp3(l),l=1,3)
              curMatElem(1,iv) = matTemp3(1) 
              curMatElem(2,iv) = matTemp3(2) 
              curMatElem(3,iv) = matTemp3(3) 
           END IF
        END IF

     
!!! FN
           
           ! Calculate the position matrix elements
           DO ii=1,3
              posMatElem(ii,iv,ic) = position(ii,iv,ic,ik)
              posMatElem(ii,ic,iv) = conjg(posMatElem(ii,iv,ic))
           END DO

102        FORMAT(6E15.7)
           
           ! Write out the position matrix elements
           IF (writeoutMEdata) THEN
              WRITE(12,102) REAL(posMatElem(1,iv,ic)),IMAG(posMatElem(1,iv,ic)) &
                   , REAL(posMatElem(2,iv,ic)),IMAG(posMatElem(2,iv,ic)) &
                   , REAL(posMatElem(3,iv,ic)),IMAG(posMatElem(3,iv,ic))
           END IF
        END DO !ic=iv,nMax
     END DO !iv=1,nMax

     ! Check hermiticity of position matrix elements
     CALL check_hermiticity(ik)
     
     ! SET THE IMAGINARY PARTS OF THE DIAGONAL COMPONENTS TO ZERO BY HAND
     DO iv = 1, nMax
        momMatElem(1,iv,iv)= REAL(momMatElem(1,iv,iv)) + 0.d0*(0.d0,1.d0)
        momMatElem(2,iv,iv)= REAL(momMatElem(2,iv,iv)) + 0.d0*(0.d0,1.d0)
        momMatElem(3,iv,iv)= REAL(momMatElem(3,iv,iv)) + 0.d0*(0.d0,1.d0)
        IF ( layeredCalculation ) then
           calmomMatElem(1,iv,iv)= REAL(calmomMatElem(1,iv,iv)) + 0.d0*(0.d0,1.d0)
           calmomMatElem(2,iv,iv)= REAL(calmomMatElem(2,iv,iv)) + 0.d0*(0.d0,1.d0)
           calmomMatElem(3,iv,iv)= REAL(calmomMatElem(3,iv,iv)) + 0.d0*(0.d0,1.d0)
        END IF
     END DO
    

     ! Calculate Delta(m,n)
!     DO iv = 1, nMax
!        DO ic = 1, nMax
     DO iv = 1, nVal
        DO ic = nVal+1, nMax
           Delta(1,ic,iv) = momMatElem(1,ic,ic)-momMatElem(1,iv,iv)
           Delta(2,ic,iv) = momMatElem(2,ic,ic)-momMatElem(2,iv,iv)
           Delta(3,ic,iv) = momMatElem(3,ic,ic)-momMatElem(3,iv,iv)
           IF ( layeredCalculation ) then
               calDelta(1,ic,iv) = calmomMatElem(1,ic,ic)-calmomMatElem(1,iv,iv)
               calDelta(2,ic,iv) = calmomMatElem(2,ic,ic)-calmomMatElem(2,iv,iv)
               calDelta(3,ic,iv) = calmomMatElem(3,ic,ic)-calmomMatElem(3,iv,iv)
           END IF
        END DO
     END DO

     IF (oldStyleScissors) THEN
        band(1:nMax) = energys(ik,1:nMax)
     END IF
     
     ! Calculate the generalized derivative of the position matrix elements
     DO iv = 1, nMax
        DO ic = 1, nMax
           DO ii=1,3
              DO iii=1,3
                 derMatElem(iii,ii,iv,ic) = genderiv(iii,ii,iv,ic,ik)
              END DO
           END DO
           
           IF (writeoutMEdata) THEN
              WRITE(13,102) REAL(derMatElem(1,1,iv,ic)),IMAG(derMatElem(1,1,iv,ic)), &
                   REAL(derMatElem(2,1,iv,ic)),IMAG(derMatElem(2,1,iv,ic)), &
                   REAL(derMatElem(3,1,iv,ic)),IMAG(derMatElem(3,1,iv,ic))
              WRITE(13,102) REAL(derMatElem(1,2,iv,ic)),IMAG(derMatElem(1,2,iv,ic)), &
                   REAL(derMatElem(2,2,iv,ic)),IMAG(derMatElem(2,2,iv,ic)), &
                   REAL(derMatElem(3,2,iv,ic)),IMAG(derMatElem(3,2,iv,ic)) 
              WRITE(13,102) REAL(derMatElem(1,3,iv,ic)),IMAG(derMatElem(1,3,iv,ic)), &
                   REAL(derMatElem(2,3,iv,ic)),IMAG(derMatElem(2,3,iv,ic)), &
                   REAL(derMatElem(3,3,iv,ic)),IMAG(derMatElem(3,3,iv,ic))
           END IF
        END DO
     END DO
!
! calculates the {\cal F}^{\rma\rmb}_{nm} Eq. (A7) of Cabellos et al., PRB 80, 155205 (2009)
!

    ci=cmplx(0.d0,1.d0)

     DO iv = 1, nVal
        DO ic = nVal+1, nMax
           DO ii=1,3
              DO iii=1,3
                 efe(iv,ic,ii,iii)=cmplx(0.d0,0.d0)
                 tmpm=cmplx(0.d0,0.d0)
                 do vp=1,nVal
                    if (vp.ne.iv) then
                       tmpm=tmpm+posMatElem(iii,ic,vp)*posMatElem(ii,vp,iv)
                    end if
                 end do
                 do cp=nVal+1,nMax
                    if (cp.ne.ic) then
                       tmpm=tmpm-posMatElem(ii,ic,cp)*posMatElem(iii,cp,iv)
                    end if
                 end do
                 efe(ic,iv,ii,iii)=-scissor*(ci*tmpm+derMatElem(iii,ii,ic,iv)) 
                 efe(iv,ic,ii,iii)=-conjg(efe(ic,iv,ii,iii))
              end do
           end do
        end do
     end do

     IF ( layeredCalculation ) then
        ! Calculate the generalized derivative of the layered position matrix elements
        ! Eq (97), i.e. \eqref{rgkcal} shg-layer.tex
        DO iv = 1, nMax
           DO ic = 1, nMax
              DO ii=1,3
                 DO iii=1,3
                    GenDerCalPosition(iii,ii,iv,ic) = GenDerCalPositionf(iii,ii,iv,ic,ik)
                 END DO
              END DO
           END DO
        END DO
     END IF
!!! Now renormalize (scissor) the momentum matrix elements     
     DO iv = 1, nVal
        DO ic = nVal + 1, nMax
!!!
!!! BMS jan/29/2013: THIS IS CORRECT FOR SHG IN THE VELOCITY GAUGE.
!!! FOR OTHER RESPONSES WHERE ONE USES THE MOMENTUM INSTEAD OF THE POSITION MATRIX ELEMENTS
!!! ONE HAS YET TO CHECK THE CORRECT IMPLEMENTATION OF THE SCISSOR SHIFT
!!!
           scissorFactor = 1.d0 + scissor / (band(ic)-band(iv))
!           write(70,*)'in set_input_ascii ',scissor
           DO ii=1,3
              momMatElem(ii,iv,ic) = momMatElem(ii,iv,ic)*scissorFactor
              momMatElem(ii,ic,iv) = momMatElem(ii,ic,iv)*scissorFactor
              IF ( layeredCalculation ) then
                 calMomMatElem(ii,iv,ic) = calMomMatElem(ii,iv,ic)*scissorFactor
                 calMomMatElem(ii,ic,iv) = calMomMatElem(ii,ic,iv)*scissorFactor
              end IF
           END DO
        END DO
     END DO
!!! 

!!! Now use the scissored energy bands !!!!!!!!!!
     
     band(1:nMax) = energys(ik,1:nMax)

!!! Now calculate the integrands
    

     CALL calculateintegrands
     
  END DO !ik=1,kMax
  
  ! CALL closefiles
  CALL closeOutputDataFiles
  !
  ! Check that we are really at the end of the input pmn file
  !
  matTemp(1:6) = 0.d0
  READ(11,*,IOSTAT=io_status) (matTemp(l), l=1,6)
  IF (io_status.LE.0) THEN
     WRITE(6,*) 'End of matrix elements file reached'
     call system("touch endWELLpmn")
     CLOSE(11)
  ELSE IF(io_status.EQ.0) THEN
     WRITE(6,*) (matTemp(l), l=1,6)
     STOP 'pmn file contains more data than expected'
  ELSE
     STOP 'reading end of pmn file caused an error.'
  END IF
  
  IF (writeoutMEdata) THEN
     CLOSE(12)
     CLOSE(13)
  END IF
  
 ! IF (nSpinor==2) THEN
 !    CLOSE(41)
 ! END IF
  
! close the spin file 
  INQUIRE(FILE=smn_data_filename, EXIST=spinCalculation)
  if ( spinCalculation) then
     CLOSE(41)
  END IF
!

  CALL deallocateArrays
  
!!!******************
END PROGRAM set_input
!!!******************

!###############################
SUBROUTINE check_hermiticity(ik)
!###############################
  USE arrays, ONLY: DPC, momMatElem, nMax, posMatElem
  IMPLICIT NONE
  INTEGER :: ik
  INTEGER :: iv, ic, ii
  COMPLEX(DPC) :: ctmpa(3), ctmpb(3)
! check for reality
  DO iv=1,nMax
     ctmpa(1:3) = momMatElem(1:3,iv,iv)
     DO ii=1,3
        IF (IMAG(ctmpa(ii)).GT.3.d-5) THEN
! YES I KNOW 2d-5 IS VERY LARGE STILL
!           WRITE(6,*) iv, ctmpa(ii)
!           PAUSE
        END IF
     END DO
  END DO
! check for hermiticity
  DO iv=2, nMax-1
     DO ic=iv+1, nMax
        ctmpa(1:3) = momMatElem(1:3,iv,ic)
        ctmpb(1:3) = momMatElem(1:3,ic,iv)
        DO ii = 1, 3
           IF (ctmpa(ii).NE.CONJG(ctmpb(ii))) THEN
              WRITE(6,*) iv,ic,ik,ii,ctmpa(ii),ctmpb(ii)
              PAUSE 'pmn not hermitian'
105           FORMAT(4I5,4E17.7)
           END IF
        END DO
        ctmpa(1:3) = posMatElem(1:3,iv,ic)
        ctmpb(1:3) = posMatElem(1:3,ic,iv)
        DO ii = 1, 3
           IF (ctmpa(ii).NE.CONJG(ctmpb(ii))) THEN
              WRITE(6,*) iv,ic,ik,ii,ctmpa(ii),ctmpb(ii)
              PAUSE 'rmn not hermitian'
           END IF
        END DO
     END DO
  END DO

!  WRITE(6,*) 'End check for kpoint', ik
!*******************************
END SUBROUTINE check_hermiticity
!*******************************
