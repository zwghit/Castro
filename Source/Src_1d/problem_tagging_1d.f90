module problem_tagging_module

  implicit none

  public

contains

  ! This is a template routine for users to set their own tags based on the state.
  ! It will be overwritten by having a copy of this file in the user's problem setup.
  
  subroutine set_problem_tags(tag,tagl1,tagh1, &
                              state,state_l1,state_h1,&
                              set,clear,&
                              lo,hi,&
                              dx,problo,time,level) &
                              bind(C, name="set_problem_tags")

    use meth_params_module, only: URHO, UMX, UEDEN, NVAR

    implicit none

    integer         ,intent(in   ) :: lo(1),hi(1)
    integer         ,intent(in   ) :: state_l1,state_h1
    integer         ,intent(in   ) :: tagl1,tagh1
    double precision,intent(in   ) :: state(state_l1:state_h1,NVAR)
    integer         ,intent(inout) :: tag(tagl1:tagh1)
    double precision,intent(in   ) :: problo(1),dx(1),time
    integer         ,intent(in   ) :: level,set,clear

  end subroutine set_problem_tags

end module problem_tagging_module
