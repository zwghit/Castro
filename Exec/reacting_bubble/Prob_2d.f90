subroutine PROBINIT (init,name,namlen,problo,probhi)

  use probdata_module
  use model_parser_module
  use bl_error_module

  implicit none

  integer init, namlen
  integer name(namlen)
  double precision problo(2), probhi(2)

  integer untin,i

  namelist /fortin/ model_name, pert_temp_factor, pert_rad_factor

  integer, parameter :: maxlen = 256
  character probin*(maxlen)

  ! Build "probin" filename from C++ land --
  ! the name of file containing fortin namelist.

  if (namlen .gt. maxlen) call bl_error("probin file name too long")

  do i = 1, namlen
     probin(i:i) = char(name(i))
  end do


  ! Namelist defaults

  ! Read namelists
  untin = 9
  open(untin,file=probin(1:namlen),form='formatted',status='old')
  read(untin,fortin)
  close(unit=untin)


  ! Read initial model
  call read_model_file(model_name)

end subroutine PROBINIT


! ::: -----------------------------------------------------------
! ::: This routine is called at problem setup time and is used
! ::: to initialize data on each grid.
! :::
! ::: NOTE:  all arrays have one cell of ghost zones surrounding
! :::        the grid interior.  Values in these cells need not
! :::        be set here.
! :::
! ::: INPUTS/OUTPUTS:
! :::
! ::: level     => amr level of grid
! ::: time      => time at which to init data
! ::: lo,hi     => index limits of grid interior (cell centered)
! ::: nstate    => number of state components.  You should know
! :::		   this already!
! ::: state     <=  Scalar array
! ::: delta     => cell size
! ::: xlo,xhi   => physical locations of lower left and upper
! :::              right hand corner of grid.  (does not include
! :::		   ghost region).
! ::: -----------------------------------------------------------
subroutine ca_initdata(level,time,lo,hi,nscal, &
                       state,state_l1,state_l2,state_h1,state_h2, &
                       delta,xlo,xhi)

  use probdata_module
  use interpolate_module
  use eos_module
  use meth_params_module, only : NVAR, URHO, UMX, UMZ, UEDEN, UEINT, UFS, UTEMP
  use network, only: nspec
  use model_parser_module
  
  implicit none

  integer level, nscal
  integer lo(2), hi(2)
  integer state_l1,state_l2,state_h1,state_h2
  double precision xlo(2), xhi(2), time, delta(2)
  double precision state(state_l1:state_h1,state_l2:state_h2,NVAR)

  double precision dist,x,y
  integer i,j,n

  double precision t0,x1,y1,r1,x2,y2,r2,x3,y3,r3,x4,y4,r4,temp

  double precision temppres(state_l1:state_h1,state_l2:state_h2)

  type (eos_t) :: eos_state

  do j = lo(2), hi(2)
     y = xlo(2) + delta(2)*(float(j-lo(2)) + 0.5d0)
     do i = lo(1), hi(1)

        state(i,j,URHO)  = interpolate(y,npts_model,model_r, &
                                       model_state(:,idens_model))
        state(i,j,UTEMP) = interpolate(y,npts_model,model_r, &
                                       model_state(:,itemp_model))
        do n = 1, nspec
           state(i,j,UFS-1+n) = interpolate(y,npts_model,model_r, &
                                            model_state(:,ispec_model-1+n))
        enddo

     enddo
  enddo

  do j = lo(2), hi(2)
     do i = lo(1), hi(1)
        eos_state%rho = state(i,j,URHO)
        eos_state%T = state(i,j,UTEMP)
        eos_state%xn(:) = state(i,j,UFS:)

        call eos(eos_input_rt, eos_state)

        state(i,j,UEINT) = eos_state%e
        temppres(i,j) = eos_state%p
     end do
  end do

  do j = lo(2), hi(2)
     do i = lo(1), hi(1)

        state(i,j,UEDEN) = state(i,j,URHO) * state(i,j,UEINT)
        state(i,j,UEINT) = state(i,j,URHO) * state(i,j,UEINT)

        do n = 1,nspec
           state(i,j,UFS+n-1) = state(i,j,URHO) * state(i,j,UFS+n-1)
        end do

     enddo
  enddo

  ! Initial velocities = 0
  state(:,:,UMX:UMZ) = 0.d0

  ! Now add the perturbation
  do j = lo(2), hi(2)
     y = xlo(2) + delta(2)*(float(j-lo(2)) + 0.5d0)
     do i = lo(1), hi(1)
        x = xlo(1) + delta(1)*(float(i-lo(1)) + 0.5d0)

        t0 = state(i,j,UTEMP)

        x1 = 5.0d7
        y1 = 6.5d7
        r1 = sqrt( (x-x1)**2 +(y-y1)**2 ) / (2.5d6*pert_rad_factor)

        x2 = 1.2d8
        y2 = 8.5d7
        r2 = sqrt( (x-x2)**2 +(y-y2)**2 ) / (2.5d6*pert_rad_factor)

        x3 = 2.0d8
        y3 = 7.5d7
        r3 = sqrt( (x-x3)**2 +(y-y3)**2 ) / (2.5d6*pert_rad_factor)

        state(i,j,UTEMP) = t0 * (1.d0 + pert_temp_factor* &
             (0.150d0 * (1.d0 + tanh(2.d0-r1)) + &
              0.300d0 * (1.d0 + tanh(2.d0-r2)) + &
              0.225d0 * (1.d0 + tanh(2.d0-r3))))

        state(i,j,UEINT) = state(i,j,UEINT) / state(i,j,URHO)

        do n = 1,nspec
           state(i,j,UFS+n-1) =  state(i,j,UFS+n-1) / state(i,j,URHO)
        end do

        eos_state%T = state(i,j,UTEMP)
        eos_state%p = temppres(i,j)
        eos_state%xn(:) = state(i,j,UFS:)

        call eos(eos_input_tp, eos_state)

        state(i,j,UEINT) = eos_state%e
        state(i,j,URHO) = eos_state%rho

        state(i,j,UEDEN) = state(i,j,UEINT)*state(i,j,URHO)
        state(i,j,UEINT) = state(i,j,UEINT)*state(i,j,URHO)

        do n = 1,nspec
           state(i,j,UFS+n-1) = state(i,j,URHO) * state(i,j,UFS+n-1)
        end do

     end do
  end do

end subroutine ca_initdata
